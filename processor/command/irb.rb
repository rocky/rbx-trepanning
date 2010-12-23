# Copyright (C) 2010 Rocky Bernstein <rockyb@rubyforge.net>
require 'irb'
require 'rubygems'; require 'require_relative'
require_relative 'base/cmd'
require_relative '../../app/irb'
class Trepan::Command::IRBCommand < Trepan::Command

  unless defined?(HELP)
    NAME = File.basename(__FILE__, '.rb')
    HELP = <<-HELP 
#{NAME} [-d]\tstarts an Interactive Ruby (IRB) session.

If -d is added you can get access to debugger frame the global variables
$trepanx_frame and $trepanx_cmdproc. 

#{NAME} is extended with methods 'cont', 'ne', and, 'q', 'step' which 
run the corresponding debugger commands 'continue', 'next', 'exit' and 'step'. 

To issue a debugger command, inside #{NAME} nested inside a debugger use
'dbgr'. For example:

  dbgr %w(info program)
  dbgr('info', 'program') # Same as above
  dbgr 'info program'     # Single quoted string also works

But arguments have to be quoted because #{NAME} will evaluate them:

  dbgr info program     # wrong!
  dbgr info, program    # wrong!
  dbgr(info, program)   # What I say 3 times is wrong!

Here then is a loop to query VM stack values:
  (-1..1).each {|i| dbgr(\"info reg sp \#{i}\")}
    HELP

    CATEGORY     = 'support'
    MAX_ARGS     = 1  # Need at most this many
    SHORT_HELP  = "Run #{NAME} as a command subshell"
  end

  # This method runs the command
  def run(args) # :nodoc
    add_debugging = 
      if args.size > 1
        '-d' == args[1]
      else
        false
      end

    # unless @state.interface.kind_of?(LocalInterface)
    #   print "Command is available only in local mode.\n"
    #   throw :debug_error
    # end

    save_trap = trap('SIGINT') do
      throw :IRB_EXIT, :cont if $trepanx_in_irb
    end

    $trepanx = @proc.dbgr 
    if add_debugging
      $trepanx_cmdproc  = @proc
      $trepanx_frame    = @proc.frame
    end
    $trepanx_in_irb = true
    $trepanx_irb_statements = nil
    $trepanx_command = nil

    conf = {:BACK_TRACE_LIMIT => settings[:maxstack]}
    cont = IRB.start_session(@proc.frame.binding, @proc, conf).to_s
    trap('SIGINT', save_trap) # Restore old trap

    back_trace_limit = IRB.CurrentContext.back_trace_limit
    if settings[:maxstack] !=  back_trace_limit
      msg("\nSetting debugger's BACK_TRACE_LIMIT (%d) to match irb's last setting (%d)" % 
          [settings[:maxstack], back_trace_limit])
      settings[:maxstack]= IRB.CurrentContext.back_trace_limit
    end

    if %w(continue finish next ext step).member?(cont)
      @proc.commands[cont].run([cont]) # (1, {})
    else
      @proc.print_location
    end
  ensure
    $trepanx_in_irb = false
    # restore old trap if any
    trap('SIGINT', save_trap) if save_trap
  end
end

if __FILE__ == $0
  require_relative '../mock'
  dbgr, cmd = MockDebugger::setup
  # Get an IRB session -- the hard way :-)
  cmd.run([cmd.name]) if ARGV.size > 0
end
