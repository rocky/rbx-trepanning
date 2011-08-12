#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# Copyright (C) 2010, 2011 Rocky Bernstein <rockyb@rubyforge.net>
require 'readline'
require 'compiler/iseq'

require 'rubygems'; require 'require_relative'
require_relative '../app/complete'       # command completion
require_relative '../app/frame'
require_relative '../app/util'           # get_dollar_0
require_relative '../processor'
require_relative '../app/breakpoint'
require_relative '../app/default'        # default debugger settings
require_relative '../app/breakpoint'
require_relative '../interface/user'     # user interface (includes I/O)
require_relative '../interface/script'   # --command interface (includes I/O)
require_relative '../interface/client'   # client interface (remote debugging)
require_relative '../interface/server'   # server interface (remote debugging)
require_relative '../io/null_output'
  
#
# The Rubinius Trepan debugger.
#
# This debugger is wired into the debugging APIs provided by Rubinius.
#

class Trepan
  attr_accessor :breakpoint   # Breakpoint. The current breakpoint we are
                              # stopped at or nil if none.
  attr_accessor :intf         # Array. The way the outside world
                              # interfaces with us.  An array, so that
                              # interfaces can be stacked.
  attr_accessor :restart_argv # How to restart us, empty or nil.
                              # Note: restart_argv is typically C's
                              # **argv, not Ruby's ARGV. So
                              # restart_argv[0] is $0.
  attr_reader   :settings     # Hash[:symbol] of things you can configure
  attr_reader   :deferred_breakpoints
  attr_reader   :processor

  # Create a new debugger object. The debugger starts up a thread
  # which is where the command line interface executes from. Other
  # threads that you wish to debug are told that their debugging
  # thread is the debugger thread. This is how the debugger is handed
  # control of execution.
  #
  def initialize(settings={})
    @breakpoint = nil
    @settings = DEFAULT_SETTINGS.merge(settings)
    @input  = @settings[:input] || STDIN
    @output = @settings[:output] || STDOUT

    cmdproc_settings = {:highlight => @settings[:highlight]}

    @processor = CmdProcessor.new(self, cmdproc_settings)
    @completion_proc = method(:completion_method)

    @in_deferred_checking = false
        
    @intf = 
      if @settings[:server]
        @completion_proc = nil
        opts = Trepan::ServerInterface::DEFAULT_INIT_CONNECTION_OPTS.dup
        opts[:port] = @settings[:port] if @settings[:port]
        opts[:host] = @settings[:host] if @settings[:host]
        opts[:readline] = false
        puts("starting debugger in out-of-process mode port at " +
             "#{opts[:host]}:#{opts[:port]}")
        [Trepan::ServerInterface.new(nil, nil, opts)]
      elsif @settings[:client]
        opts = Trepan::ClientInterface::DEFAULT_INIT_CONNECTION_OPTS.dup
        opts[:port] = @settings[:port] if @settings[:port]
        opts[:host] = @settings[:host] if @settings[:host]
        opts[:complete] = @completion_proc
        opts[:readline] ||= @settings[:readline]
        [Trepan::ClientInterface.new(nil, nil, nil, nil, opts)]
      else
        opts = {:complete => @completion_proc,
                :readline => @settings[:readline]}
        [Trepan::UserInterface.new(@input, @output, opts)]
      end

    process_cmdfile_setting(@settings)
    if @settings[:initial_dir]
      Dir.chdir(@settings[:initial_dir])
    else
      @settings[:initial_dir] = Dir.pwd
    end
    @initial_dir  = @settings[:initial_dir]
    @restart_argv = @settings[:restart_argv]

    ## FIXME: Delete these and use the ones in processor/default instead.
    @variables = {
      :show_bytecode => false,
    }

    @processor.dbgr = self
    @deferred_breakpoints = []
    @thread = nil
    @frames = []

    unless @settings[:client]
      ## FIXME: put in fn
      ## m = Rubinius::Loader.method(:debugger).executable.inspect
      meth = Rubinius::VM.backtrace(0)[0].method
      @processor.ignore_methods[meth] = 'next'
      @processor.ignore_methods[method(:debugger)] = 'step'

      @loaded_hook = proc { |file|
        check_deferred_breakpoints
      }
      
      @added_hook = proc { |mod, name, exec|
        check_deferred_breakpoints
      }

      # Use a few Rubinius-specific hooks to trigger checking
      # for deferred breakpoints.
      
      Rubinius::CodeLoader.loaded_hook.add @loaded_hook
      Rubinius.add_method_hook.add @added_hook
      
    end

    # Run user debugger command startup files.
    add_startup_files unless @settings[:nx]
  end

  # The method is called when we want to do debugger command completion
  # such as called from GNU Readline with <TAB>.
  def completion_method(last_token, leading=Readline.line_buffer)
    completion = @processor.complete(leading, last_token)
    if 1 == completion.size 
      completion_token = completion[0]
      if last_token.end_with?(' ')
        if last_token.rstrip == completion_token 
          # There is nothing more to complete
          []
        else
          []
        end
      else
        [completion_token]
      end
    else
      # We have multiple completions. Get the last token so that will
      # be presented as a list of completions.
      completion
    end
  end

  ## HACK to skip over loader code. Until I find something better...
  def skip_loader
    cmds = 
      if @settings[:skip_loader] == :Xdebug
        ['continue Rubinius::CodeLoader.load_script',
         'continue 67',
         # 'set kernelstep off',   # eventually would like 'on'
         'step', 'set hidelevel -1'
        ]
      else
        ['next', 'next', 'next',
         # 'set kernelstep off',  # eventually would like 'on'
         'set hidelevel -1',
         'step', ]
      end

    input = Trepan::StringArrayInput.open(cmds)
    startup = Trepan::ScriptInterface.new('startup', 
                                          Trepan::OutputNull.new(nil),
                                          :input => input)
    @intf << startup
  end

  attr_reader :completion_proc # GNU Readline completion proc
  attr_reader :variables, :current_frame, :breakpoints
  attr_reader :vm_locations, :debugee_thread

  def self.global(settings={})
    @global ||= new(settings)
  end

  def self.start(settings={})
    settings = {:immediate => false, :offset => 1}.merge(settings)
    global(settings).start(settings)
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
  def debugger(settings = {:immediate => false})
    @settings = @settings.merge(settings)
    skip_loader if @settings[:skip_loader]
    spinup_thread
    @debugee_thread = @thread
    if @settings[:hide_level]
      @processor.hidelevels[@thread] = @settings[:hide_level]
    end

    process_cmdfile_setting(settings)

    # Feed info (breakpoint, debugged program thread, channel and backtrace 
    # info) to the debugger thread
    locs = Rubinius::VM.backtrace(@settings[:offset] + 1, true)

    method = Rubinius::CompiledMethod.of_sender

    event = settings[:immediate] ? 'debugger-call' : 'start'
    bp = Breakpoint.new('<start>', method, 0, 0, 0, {:event => event} )
    channel = Rubinius::Channel.new

    @local_channel.send Rubinius::Tuple[bp, Thread.current, channel, locs]

    # wait for the debugger to release us
    channel.receive

    # Now that there is a debugger on the other end, set the debugged 
    # program thread to call us when it hits a breakpoint.
    Thread.current.set_debugger_thread @thread
    self
  end
  alias start debugger

  def stop(settings = {})
    @processor.finalize
    # Rubinius::VM.debug_channel = nil
  end

  def add_command_file(cmdfile, opts={}, stderr=$stderr)
    unless File.readable?(cmdfile)
      if File.exists?(cmdfile)
        stderr.puts "Command file '#{cmdfile}' is not readable."
        return
      else
        stderr.puts "Command file '#{cmdfile}' does not exist."
        return
      end
    end
    @intf << Trepan::ScriptInterface.new(cmdfile, @output, opts)
  end

  def add_startup_files()
    seen = {}
    cwd_initfile = File.join('.', Trepan::CMD_INITFILE_BASE)
    [cwd_initfile, Trepan::CMD_INITFILE].each do |initfile|
      full_initfile_path = File.expand_path(initfile)
      next if seen[full_initfile_path]
      add_command_file(full_initfile_path) if File.readable?(full_initfile_path)
      seen[full_initfile_path] = true
    end
  end

  def process_cmdfile_setting(settings)
    settings[:cmdfiles].each do |item|
      cmdfile, opts = 
        if item.kind_of?(Array)
          item
        else
          [item, {}]
        end
      add_command_file(cmdfile, opts)
    end if settings.member?(:cmdfiles)
  end

  # Stop and wait for a debuggee thread to send us info about
  # stopping at a breakpoint.
  #
  def listen(step_into=false)
    @breakpoint = nil
    while true
      if @channel
        if step_into
          @channel << :step
        else
          @channel << true
        end
      end

      # Wait for someone to stop
      @breakpoint, @debugee_thread, @channel, @vm_locations = 
        @local_channel.receive

      # Uncache all frames since we stopped at a new place
      @frames = []

      set_frame(0)

      if @breakpoint
        # Some breakpoints are frame specific. Check for this.  hit!
        # also removes the breakpoint if it was temporary and hit.
        status = @breakpoint.hit!(@vm_locations.first.variables)
        if status
          break
        elsif @breakpoint.enabled? && status.nil? 
          # A permanent breakpoint. Check the condition.
          break if @breakpoint.condition?(@current_frame.binding)
        end
      else
        @processor.remove_step_brkpt
        break
      end
    end

    event = 
      if @breakpoint
        @breakpoint.event || 'brkpt'
      else
        # Evan assures me that the only way the breakpoint can be nil
        # is if we are stepping and enter a function.
        'step-call'
      end
    @processor.instance_variable_set('@event', event)

    if @variables[:show_bytecode]
      decode_one
    end

  end

  def frame(num)
    @frames[num] ||= Frame.new(self, num, @vm_locations[num])
  end

  def set_frame(num)
    @current_frame = frame(num)
  end

  def each_frame(start=0)
    start = start.number if start.kind_of?(Frame)

    start.upto(@vm_locations.size-1) do |idx|
      yield frame(idx)
    end
  end

  def add_deferred_breakpoint(klass_name, which, name, line)
    dbp = Trepan::DeferredBreakpoint.new(self, @current_frame, klass_name, 
                                         which, name, line, 
                                         @deferred_breakpoints)
    @deferred_breakpoints << dbp
    # @processor.brkpts << dbp
  end

  def check_deferred_breakpoints
    unless @in_deferred_checking 
      @in_deferred_checking = true
      @deferred_breakpoints.delete_if do |bp|
        bp.resolve!
      end
      @in_deferred_checking = false
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
      # if @variables[:highlight]
      #   fin = @current_frame.method.first_ip_on_line(line + 1)
      #   name = send_between(@current_frame.method, @current_frame.ip, fin)

      #   if name
      #     str = str.gsub name.to_s, "\033[0;4m#{name}\033[0m"
      #   end
      # end
      # info "#{line}: #{str}"
    else
      show_bytecode(line)
    end
  end

  def decode_one
    ip = @current_frame.next_ip

    meth = @current_frame.method
    decoder = Rubinius::InstructionDecoder.new(meth.iseq)
    partial = decoder.decode_between(ip, ip+1)

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

      puts "=> ip #{ip} = #{op.opcode} #{ins.join(', ')}"
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

module Kernel
  # A simpler way of calling Trepan.start
  def debugger(settings = {})
    settings = {:immediate => false, :offset => 2}.merge(settings)
    Trepan.start(settings)
  end
  alias breakpoint debugger unless respond_to?(:breakpoint)
end

if __FILE__ == $0
  if ARGV.size > 0
    debugger
    x = 1
  end
end
