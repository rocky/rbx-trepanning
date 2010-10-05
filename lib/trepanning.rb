require 'readline'

require 'rubygems'; require 'require_relative'
require_relative '../app/frame'
require_relative '../processor/main'
require_relative '../app/breakpoint'
require_relative '../app/default'        # default debugger settings
require_relative '../app/breakpoint'
require_relative '../app/display'
require_relative '../interface/user'     # user interface (includes I/O)
  
#
# The Rubinius Trepan debugger.
#
# This debugger is wired into the debugging APIs provided by Rubinius.
#

class Trepan
  VERSION = '0.0.1.git'

  attr_accessor :intf         # Array. The way the outside world
                              # interfaces with us.  An array, so that
                              # interfaces with us.  An array, so that
                              # interfaces can be stacked.
  attr_reader   :initial_dir  # String. Current directory when program
                              # started. Used in restart program.
  attr_accessor :restart_argv # How to restart us, empty or nil. 
                              # Note restart_argv[0] is typically $0.
  attr_reader   :settings     # Hash[:symbol] of things you can configure

  # Used to try and show the source for the kernel. Should
  # mostly work, but it's a hack.
  DBGR_DIR = File.dirname(RequireRelative.abs_file)
  ROOT_DIR = File.expand_path(File.join(DBGR_DIR, "/.."))

  include Trepan::Display

  # Create a new debugger object. The debugger starts up a thread
  # which is where the command line interface executes from. Other
  # threads that you wish to debug are told that their debugging
  # thread is the debugger thread. This is how the debugger is handed
  # control of execution.
  #
  def initialize(settings={})
    @settings = Trepanning::DEFAULT_SETTINGS.merge(settings)

    @processor = CmdProcessor.new(self)
    @intf     = [Trepan::UserInterface.new(@input, @output)]
    @settings[:cmdfiles].each do |cmdfile|
      add_command_file(cmdfile)
    end if @settings.member?(:cmdfiles)
    ## @core     = Core.new(self, @settings[:core_opts])
    if @settings[:initial_dir]
      Dir.chdir(@settings[:initial_dir])
    else
      @settings[:initial_dir] = Dir.pwd
    end
    @initial_dir  = @settings[:initial_dir]
    @restart_argv = 
      if @settings[:set_restart]
        [File.expand_path($0)] + ARGV
      elsif @settings[:restart_argv]
        @settings[:restart_argv]
      else 
        nil
      end

    @processor.dbgr = self

    @thread = nil
    @frames = []
    ## FIXME: Delete these and use the ones in processor/default instead.
    @variables = {
      :show_bytecode => false,
      :highlight => false
    }

    @loaded_hook = proc { |file|
      check_deferred_breakpoints
    }

    @added_hook = proc { |mod, name, exec|
      check_deferred_breakpoints
    }

    # Use a few Rubinius specific hooks to trigger checking
    # for deferred breakpoints.

    Rubinius::CodeLoader.loaded_hook.add @loaded_hook
    Rubinius.add_method_hook.add @added_hook

    @deferred_breakpoints = []

    @breakpoints = []

    @history_path = File.expand_path("~/.trepanx")

    if File.exists?(@history_path)
      File.readlines(@history_path).each do |line|
        Readline::HISTORY << line.strip
      end
      @history_io = File.new(@history_path, "a")
    else
      @history_io = File.new(@history_path, "w")
    end

    @history_io.sync = true

    @root_dir = ROOT_DIR

    # Run user debugger command startup files.
    add_startup_files unless @settings[:nx]
    add_command_file(@settings[:restore_profile]) if 
      @settings[:restore_profile] && File.readable?(@settings[:restore_profile])
  end

  attr_reader :variables, :current_frame, :breakpoints
  attr_reader :locations, :history_io, :debugee_thread

  def self.global(settings={})
    @global ||= new(settings)
  end

  def self.start(settings={})
    global(settings).start(:offset => 1)
  end

  # This is simplest API point. This starts up the debugger in the caller
  # of this method to begin debugging.
  #
  def self.here(settings={})
    global(settings).start(:offset => 1)
  end

  # Startup the debugger, skipping back +offset+ frames. This lets you start
  # the debugger straight into callers method.
  #
  def start(settings = {})
    @settings = @settings.merge(settings)
    spinup_thread

    # Feed info to the debugger thread!
    locs = Rubinius::VM.backtrace(@settings[:offset] + 1, true)

    method = Rubinius::CompiledMethod.of_sender

    bp = Trepanning::BreakPoint.new "<start>", method, 0, 0, 0
    channel = Rubinius::Channel.new

    @local_channel.send Rubinius::Tuple[bp, Thread.current, channel, locs]

    # wait for the debugger to release us
    channel.receive

    Thread.current.set_debugger_thread @thread
    self
  end

  def add_command_file(cmdfile, stderr=$stderr)
    unless File.readable?(cmdfile)
      if File.exists?(cmdfile)
        stderr.puts "Command file '#{cmdfile}' is not readable."
        return
      else
        stderr.puts "Command file '#{cmdfile}' does not exist."
        stderr.puts caller
        return
      end
    end
    @intf << Trepan::ScriptInterface.new(cmdfile, @output)
  end

  def add_startup_files()
    seen = {}
    cwd_initfile = File.join('.', Trepanning::CMD_INITFILE_BASE)
    [cwd_initfile, Trepanning::CMD_INITFILE].each do |initfile|
      full_initfile_path = File.expand_path(initfile)
      next if seen[full_initfile_path]
      add_command_file(full_initfile_path) if File.readable?(full_initfile_path)
      seen[full_initfile_path] = true
    end
  end

  # Stop and wait for a debuggee thread to send us info about
  # stoping at a breakpoint.
  #
  def listen(step_into=false)
    if @channel
      if step_into
        @channel << :step
      else
        @channel << true
      end
    end

    # Wait for someone to stop
    bp, thr, chan, locs = @local_channel.receive

    # Uncache all frames since we stopped at a new place
    @frames = []

    @locations = locs
    @breakpoint = bp
    @debuggee_thread = thr
    @channel = chan

    @current_frame = @processor.frame = frame(0)

    bp.hit! if bp

    puts
    info "Breakpoint: #{@current_frame.describe}"
    show_code

    if @variables[:show_bytecode]
      decode_one
    end

  end

  def frame(num)
    @frames[num] ||= Frame.new(self, num, @locations[num])
  end

  def set_frame(num)
    @current_frame = frame(num)
  end

  def each_frame(start=0)
    start = start.number if start.kind_of?(Frame)

    start.upto(@locations.size-1) do |idx|
      yield frame(idx)
    end
  end

  def set_breakpoint_method(descriptor, method, line=nil)
    exec = method.executable

    unless exec.kind_of?(Rubinius::CompiledMethod)
      error "Unsupported method type: #{exec.class}"
      return
    end

    if line
      ip = exec.first_ip_on_line(line)

      if ip == -1
        error "Unknown line '#{line}' in method '#{method.name}'"
        return
      end
    else
      line = exec.first_line
      ip = 0
    end

    id = @breakpoints.size
    bp = Treapanning::BreakPoint.new(descriptor, exec, ip, line, id+1)
    bp.activate

    @breakpoints << bp

    info "Set breakpoint #{id+1}: #{bp.location}"

    return bp
  end

  def add_deferred_breakpoint(klass_name, which, name, line)
    dbp = Trepanning::DeferredBreakPoint.new(self, @current_frame, klass_name, which, name,
                                             line, @deferred_breakpoints)
    @deferred_breakpoints << dbp
    @breakpoints << dbp
  end

  def check_deferred_breakpoints
    @deferred_breakpoints.delete_if do |bp|
      bp.resolve!
    end
  end

  def send_between(exec, start, fin)
    ss   = Rubinius::InstructionSet.opcodes_map[:send_stack]
    sm   = Rubinius::InstructionSet.opcodes_map[:send_method]
    sb   = Rubinius::InstructionSet.opcodes_map[:send_stack_with_block]

    iseq = exec.iseq

    fin = iseq.size if fin < 0

    i = start
    while i < fin
      op = iseq[i]
      case op
      when ss, sm, sb
        return exec.literals[iseq[i + 1]]
      else
        op = Rubinius::InstructionSet[op]
        i += (op.arg_count + 1)
      end
    end

    return nil
  end

  def show_code(line=@current_frame.line)
    path = @current_frame.method.active_path
    str = @processor.line_at(path, line)
    unless str.nil?
      if @variables[:highlight]
        fin = @current_frame.method.first_ip_on_line(line + 1)
        name = send_between(@current_frame.method, @current_frame.ip, fin)

        if name
          str = str.gsub name.to_s, "\033[0;4m#{name}\033[0m"
        end
      end
      info "#{line}: #{str}"
    else
      show_bytecode(line)
    end
  end

  def decode_one
    ip = @current_frame.ip

    meth = @current_frame.method
    partial = meth.iseq.decode_between(ip, ip+1)

    partial.each do |ins|
      op = ins.shift

      ins.each_index do |i|
        case op.args[i]
        when :literal
          ins[i] = meth.literals[ins[i]].inspect
        when :local
          if meth.local_names
            ins[i] = meth.local_names[ins[i]]
          end
        end
      end

      display "ip #{ip} = #{op.opcode} #{ins.join(', ')}"
    end
  end

  def show_bytecode(line=@current_frame.line)
    meth = @current_frame.method
    start = meth.first_ip_on_line(line)
    fin = meth.first_ip_on_line(line+1)

    if fin == -1
      fin = meth.iseq.size
    end

    section "Bytecode between #{start} and #{fin-1} for line #{line}"

    iseq_decoder = Rubinius::InstructionDecoder.new(meth.iseq)
    partial = iseq_decoder.decode_between(start, fin)

    ip = start

    partial.each do |ins|
      op = ins.shift

      ins.each_index do |i|
        case op.args[i]
        when :literal
          ins[i] = meth.literals[ins[i]].inspect
        when :local
          if meth.local_names
            ins[i] = meth.local_names[ins[i]]
          end
        end
      end

      info " %4d: #{op.opcode} #{ins.join(', ')}" % ip

      ip += (ins.size + 1)
    end
  end

  def spinup_thread
    return if @thread

    @local_channel = Rubinius::Channel.new

    @thread = Thread.new do
      begin
        listen
      rescue Exception => e
        e.render("Listening")
        break
      end

      @processor.process_commands

    end

    @thread.setup_control!(@local_channel)
  end

  private :spinup_thread

end
