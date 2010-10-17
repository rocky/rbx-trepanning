require 'rubygems'; require 'require_relative'
require_relative 'base/cmd'
require_relative '../stepping'

class Trepan::Command::ContinueCommand < Trepan::Command
  ALIASES      = %w(c cont)
  CATEGORY     = 'running'
  NAME         = File.basename(__FILE__, '.rb')
  HELP         = <<-HELP
  NEED_RUNNING = true
Continue execution until another breakpoint is hit.

See also 'step', 'next', and 'nexti' commands.
      HELP
  SHORT_HELP   =  'Continue running the target thread'

  def run(args)
    @proc.continue('continue')
  end
end

if __FILE__ == $0
  require_relative '../mock'
  dbgr, cmd = MockDebugger::setup
end
