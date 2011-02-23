require 'rubygems'; require 'require_relative'
require_relative 'base/cmd'
require_relative '../../app/condition'
require_relative '../stepping'

class Trepan::Command::StepCommand < Trepan::Command

  ALIASES      = %w(s s+ s- step+ step-)
  CATEGORY     = 'running'
  NAME         = File.basename(__FILE__, '.rb')
  HELP         = <<-HELP
#{NAME}[+|-] [into]  [count]
#{NAME} until EXPRESSION
#{NAME} over [args..]
#{NAME} out  [args..]

Execute the current line, stopping at the next line.  Sometimes this
is called 'step into'.

Behaves like 'next', but if there is a method call on the current line,
execution is stopped in the called method.

Examples: 
  #{NAME}        # step 1 line
  #{NAME} 1      # same as above
  #{NAME} into   # same as above
  #{NAME} into 1 # same as above
  #{NAME} 5/5+0  # same as above
  #{NAME}+       # same but force stopping on a new line
  #{NAME}-       # same but force stopping on a new line a new frame added
  #{NAME} until a > b
  #{NAME} over   # same as 'next'
  #{NAME} out    # same as 'finish'

Related and similar is the 'next' (step over) and 'finish' (step out)
commands.

See also the commands:
'continue', 'next', 'nexti' and 'finish' for other ways to progress execution.
      HELP
  NEED_RUNNING = true
  SHORT_HELP   = 'Step into next method call or to next line'

  Keyword_to_related_cmd = {
    'out'  => 'finish',
    'over' => 'next',
    'into' => 'step',
  }
  
  include Trepan::Condition
  # This method runs the command
  def run(args) # :nodoc
    condition = nil
    opts = {}
    if args.size == 1
      step_count = 1
    else
      replace_cmd = Keyword_to_related_cmd[args[1]]
      if replace_cmd
        cmd = @proc.commands[replace_cmd]
        return cmd.run([replace_cmd] + args[2..-1])
      elsif 'until' == args[1]
        try_condition = args[2..-1].join(' ')
        if valid_condition?(try_condition)
          condition = try_condition
          opts[:different_pos] = false
          step_count = 0
        end
      else
        step_str = args[1]
        opts = @proc.parse_next_step_suffix(args[0])
        count_opts = {
          :msg_on_error => 
          "The #{NAME} command argument must eval to an integer. Got: %s" % 
          step_str,
          :min_value => 1
        }
        step_count = @proc.get_an_int(step_str, count_opts)
        return unless step_count
      end
    end
    
    @proc.step('step', step_count, opts, condition)
  end
end

if __FILE__ == $0
  require_relative '../mock'
  dbgr, cmd = MockDebugger::setup
  [%W(#{cmd.name}), %W(#{cmd.name} 2), %W(#{cmd.name} into 1+2),
   %W(#{cmd.name} over)].each do |c|
    cmd.proc.instance_variable_set('@return_to_program', false)
    cmd.run(c)
    puts 'return_to_program: %s' % cmd.proc.instance_variable_get('@return_to_program')
    puts 'step_count: %s' % cmd.proc.instance_variable_get('@step_count')
  end
end
