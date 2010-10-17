require 'rubygems'; require 'require_relative'
require_relative 'base/cmd'
require_relative '../stepping'

class Trepan::Command::StepCommand < Trepan::Command

  ALIASES      = %w(s)
  CATEGORY     = 'running'
  NAME         = File.basename(__FILE__, '.rb')
  HELP         = <<-HELP
Behaves like 'next', but if there is a method call on the current line,
exception is stopped in the called method.

See also 'continue', 'next' and 'nexti' commands.
      HELP
  NEED_RUNNING = true
  SHORT_HELP   = 'Step into next method call or to next line'

  def run(args)
    @proc.step('step')
  end
end

if __FILE__ == $0
  require_relative '../mock'
  dbgr, cmd = MockDebugger::setup
end
