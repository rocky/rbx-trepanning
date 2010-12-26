require 'rubygems'; require 'require_relative'
require_relative 'base/cmd'
require_relative '../stepping'

class Trepan::Command::StepCommand < Trepan::Command

  ALIASES      = %w(s s+ s- step+ step-)
  CATEGORY     = 'running'
  NAME         = File.basename(__FILE__, '.rb')
  HELP         = <<-HELP
Behaves like 'next', but if there is a method call on the current line,
exception is stopped in the called method.

See also 'continue', 'next' and 'nexti' commands.
      HELP
  NEED_RUNNING = true
  SHORT_HELP   = 'Step into next method call or to next line'

  Keyword_to_related_cmd = {
    'out'  => 'finish',
    'over' => 'next',
    'into' => 'step',
  }
  
  def run(args)
    if args.size == 1
      step_count = 1
      opts = {}
    else
      step_str = args[1]
      opts = @proc.parse_next_step_suffix(step_str)
      count_opts = {
        :msg_on_error => 
        "The #{NAME} command argument must eval to an integer. Got: %s" % 
        step_str,
        :min_value => 1
      }
      step_count = @proc.get_an_int(step_str, count_opts)
      return unless step_count
    end
    
    @proc.step('step', step_count, opts)
  end
end

if __FILE__ == $0
  require_relative '../mock'
  dbgr, cmd = MockDebugger::setup
end
