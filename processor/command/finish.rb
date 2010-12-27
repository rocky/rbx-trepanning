# -*- coding: utf-8 -*-
# Copyright (C) 2010 Rocky Bernstein <rockyb@rubyforge.net>
require 'rubygems'; require 'require_relative'
require_relative 'base/cmd'

class Trepan::Command::FinishCommand < Trepan::Command

  unless defined?(HELP)
    NAME = File.basename(__FILE__, '.rb')
    HELP = <<-HELP
#{NAME} [levels]

Continue execution until leaving the current function. 
Sometimes this is called 'step out'.

When `levels' is specified, that many frame levels need to be
popped. The default is 1.  Note that 'yield' and exceptions raised my
reduce the number of stack frames. Also, if a thread is switched, we
stop ignoring levels.

'next>' is similar in that it stops at a return, but it doesn't
guarantee the stack level is the same as or less than the current
one. 

See the break command if you want to stop at a particular point in a
program. In general, '#{NAME}', 'step' and 'next' may slow a program down
while 'break' will have less overhead.
    HELP
    ALIASES      = %w(fin)
    CATEGORY     = 'running'
    # execution_set = ['Running']
    MAX_ARGS     = 1   # Need at most this many. 
    NEED_STACK   = true
    SHORT_HELP   = 'Step to end of current method (step out)'
  end

  # This method runs the command
  def run(args) # :nodoc
    opts = {}
    if args.size == 1
      # Form is: "finish" which means "finish 1"
      level_count = 0
    else
      count_str = args[1]
      opts = {
        :msg_on_error => 
        "The '#{NAME}' command argument must eval to an integer. Got: %s" % 
        count_str,
        :min_value => 1
      }
      count = @proc.get_an_int(count_str, opts)
      return unless count
      # step 1 is core.level_count = 0 or "stop next event"
      level_count = count - 1  
    end
    if 0 == level_count and %w(return c-return).member?(@proc.event)
      errmsg "You are already at the requested return event."
    else
      @proc.finish(level_count, opts)
    end
  end
end

if __FILE__ == $0
  require_relative '../mock'
  dbgr, cmd = MockDebugger::setup
  [%W(#{cmd.name}), %w(fin 2-1), %w(n foo)].each do |c|
    cmd.proc.instance_variable_set('@return_to_program', false)
    cmd.run(c)
    puts 'return_to_program: %s' % cmd.proc.instance_variable_get('@return_to_program')
    puts 'step_count: %s' % cmd.proc.instance_variable_get('@step_count')
  end
  [%w(fin), [cmd.name]].each do |c|
    cmd.proc.leave_cmd_loop = false
    result = cmd.run(c)
    puts cmd.proc.different_pos
  end
end
