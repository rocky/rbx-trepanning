require 'rubygems'; require 'require_relative'
require_relative 'base/cmd'

class Trepan::Command::ContinueCommand < Trepan::Command
  ALIASES      = %w(c cont)
  CATEGORY     = 'running'
  NAME         = File.basename(__FILE__, '.rb')
  NEED_RUNNING = true
  SHORT_HELP   =  'Continue running the target thread'
  HELP= <<-HELP
Continue execution until another breakpoint is hit.
      HELP
  
  def run(args)
    @proc.dbgr.listen
  end
end

if __FILE__ == $0
  require_relative '../mock'
  name = File.basename(__FILE__, '.rb')
  dbgr, cmd = MockDebugger::setup(name)
end
