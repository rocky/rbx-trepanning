# Copyright (C) 2010 Rocky Bernstein <rockyb@rubyforge.net>
# Mock setup for commands.
require 'rubygems'; require 'require_relative'

require_relative 'main'

# require_relative '../app/core'
require_relative '../app/default'
require_relative '../app/frame'
require_relative '../interface/user'  # user interface (includes I/O)

module MockDebugger
  class MockDebugger
    attr_accessor :trace_filter # Procs/Methods we ignore.

    attr_accessor :frame        # Actually a "Rubinius::Location object
    attr_accessor :core         # access to Debugger::Core instance
    attr_accessor :intf         # The way the outside world interfaces with us.
    attr_reader   :initial_dir  # String. Current directory when program
                                # started. Used in restart program.
    attr_accessor :restart_argv # How to restart us, empty or nil. 
                                # Note restart[0] is typically $0.
    attr_reader   :settings     # Hash[:symbol] of things you can configure
    attr_accessor :processor

    # FIXME: move more stuff of here and into Trepan::CmdProcessor
    # These below should go into Trepan::CmdProcessor.
    attr_reader :cmd_argstr, :cmd_name, :locations, :current_frame, 
                :debugee_thread

    def initialize(settings={})
      @before_cmdloop_hooks = []
      @settings             = Trepanning::DEFAULT_SETTINGS.merge(settings)
      @intf                 = [Trepan::UserInterface.new]
      @locations            = Rubinius::VM.backtrace(1, true)
      @current_frame        = Trepan::Frame.new(self, 0, @locations[0])
      @debugee_thread       = Thread.current
      @frames               = []

      ## @core                 = Trepan::Core.new(self)
      ## @trace_filter         = []

      # Don't allow user commands in mocks.
      ## @core.processor.settings[:user_cmd_dir] = nil 

    end

    def frame(num)
      @frames[num] ||= Trepan::Frame.new(self, num, @locations[num])
    end
  end

  # Common Mock debugger setup 
  def setup(name=nil, show_constants=true)
    unless name
      loc = Rubinius::VM.backtrace(1, true)[0]
      name = File.basename(loc.file, '.rb')
    end

    if ARGV.size > 0 && ARGV[0] == 'debug'
      require_relative '../lib/trepanning'
      dbgr = Debugger.new
      dbgr.debugger
    else
      dbgr = MockDebugger.new
    end

    cmdproc = Trepan::CmdProcessor.new(dbgr)
    cmdproc.frame = dbgr.frame(0)
    dbgr.processor = cmdproc
    
    cmdproc.load_cmds_initialize
    cmds = cmdproc.commands
    cmd  = cmds[name]
    cmd.proc.frame_setup
    show_special_class_constants(cmd) if show_constants

    def cmd.msg(message)
      puts message
    end
    def cmd.msg_nocr(message)
      print message
    end
    def cmd.errmsg(message)
      puts "Error: #{message}"
    end
    def cmd.confirm(prompt, default)
      true
    end

    return dbgr, cmd
  end
  module_function :setup

  def show_special_class_constants(cmd)
    puts 'ALIASES: %s' % [cmd.class.const_get('ALIASES').inspect] if
      cmd.class.constants.member?(:ALIASES)
    %w(CATEGORY MIN_ARGS MAX_ARGS 
       NAME NEED_STACK SHORT_HELP).each do |name|
      puts '%s: %s' % [name, cmd.class.const_get(name).inspect]
    end
    puts '-' * 30
    puts cmd.class.const_get('HELP')
    puts '=' * 30
  end
  module_function :show_special_class_constants

end

if __FILE__ == $0
  dbgr = MockDebugger::MockDebugger.new
  p dbgr.settings
  puts '=' * 10
  # p dbgr.core.processor.settings
end
