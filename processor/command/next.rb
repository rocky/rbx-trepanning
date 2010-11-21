require 'rubygems'; require 'require_relative'
require_relative 'base/cmd'
require_relative '../stepping'
require_relative '../../app/breakpoint'

class Trepan::Command::NextCommand < Trepan::Command

  ALIASES      = %w(n)
  CATEGORY     = 'running'
  NAME         = File.basename(__FILE__, '.rb')
  HELP= <<-HELP
#{NAME} [NUM]

Attempt to continue execution and stop at the next line. If there is
a conditional branch between the current position and the next line,
execution is stopped within the conditional branch instead.

The optional argument is a number which specifies how many lines to
attempt to skip past before stopping execution.

If the current line is the last in a method, execution is stopped
at the current position of the caller.

See also 'step' and 'nexti'.
      HELP
  NEED_RUNNING = true
  SHORT_HELP   =  'Move to the next line or conditional branch'

  def run(args)
    if args.size == 1
      step_count = 1
    else
      step_str = args[1]
      opts = {
        :msg_on_error => 
        "The #{NAME} command argument must eval to an integer. Got: %s" % 
        step_str,
        :min_value => 1
      }
      step_count = @proc.get_an_int(step_str, opts)
      return unless step_count
    end

    @proc.step('next', step_count)
  end
  
end

if __FILE__ == $0
  require_relative '../mock'
  dbgr, cmd = MockDebugger::setup
  # [%w(n 5), %w(next 1+2), %w(n foo)].each do |c|
  #   dbgr.core.step_count = 0
  #   cmd.proc.leave_cmd_loop = false
  #   result = cmd.run(c)
  #   puts 'Run result: %s' % result
  #   puts 'step_count %d, leave_cmd_loop: %s' % [dbgr.core.step_count,
  #                                               cmd.proc.leave_cmd_loop]
  # end
  # [%w(n), %w(next+), %w(n-)].each do |c|
  #   dbgr.core.step_count = 0
  #   cmd.proc.leave_cmd_loop = false
  #   result = cmd.run(c)
  #   puts cmd.proc.different_pos
  # end
end
