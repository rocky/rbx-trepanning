# Copyright (C) 2010, 2011 Rocky Bernstein <rockyb@rubyforge.net>
require 'rubygems'; require 'require_relative'
require_relative '../command'
require_relative '../stepping'

class Trepan::Command::ContinueCommand < Trepan::Command
  unless defined?(HELP)
    NAME = File.basename(__FILE__, '.rb')
    HELP = <<-HELP
#{NAME} [LOCATION]

Leave the debugger loop and continue execution. Subsequent entry to
the debugger however may occur via breakpoints or explicit calls, or
exceptions.

If a parameter is given, a temporary breakpoint is set at that position
before continuing. Offset are numbers prefixed with an "@" otherwise
the parameter is taken as a line number.

Examples:
   #{NAME}
   #{NAME} 10    # continue to line 10
   #{NAME} @20   # continue to VM Instruction Sequence offset 20
   #{NAME} gcd   # continue to first instruction of method gcd
   #{NAME} IRB.start @7 # continue to IRB.start offset 7

See also 'step', 'next', 'finish', 'nexti' commands and "help location".
    HELP

    ALIASES      = %w(c cont)
    CATEGORY     = 'running'
    MAX_ARGS     = 2  # Need at most this many
    NEED_RUNNING = true
    SHORT_HELP   = 'Continue execution of the debugged program'
  end

  # This is the method that runs the command
  def run(args)

    ## FIXME: DRY this code, tbreak and break.
    unless args.size == 1
      cm, line, ip, condition, negate = 
        @proc.breakpoint_position(@proc.cmd_argstr, false)
      if cm
        opts={:event => 'tbrkpt', :temp => true}
        bp = @proc.set_breakpoint_method(cm, line, ip, opts)
        bp.set_temp!
      else
        errmsg "Trouble setting temporary breakpoint"
        return 
      end
    end
    @proc.continue('continue')
  end
end

if __FILE__ == $0
  require_relative '../mock'
  dbgr, cmd = MockDebugger::setup
  p cmd.run([cmd.name])
end
