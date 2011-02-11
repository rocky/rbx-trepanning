# -*- coding: utf-8 -*-
# Copyright (C) 2011 Rocky Bernstein <rockyb@rubyforge.net>
require 'rubygems'; require 'require_relative'
require_relative './base/cmd'

class Trepan::Command::EvalCommand < Trepan::Command

  NAME          = File.basename(__FILE__, '.rb')
  CATEGORY      = 'data'
  HELP    = <<-HELP
#{NAME} [STRING]

Run code in the context of the current frame.

The value of the expression is stored into a global variable so it
may be used again easily. The name of the global variable is printed
next to the inspect output of the value.

If no string is given we run the string from the current source code
about to be run

#{NAME} 1+2  # 3
#{NAME} @v
#{NAME}      # Run current source-code line

See also 'set autoeval'
      HELP

  NAME          = File.basename(__FILE__, '.rb')
  NEED_STACK    = true
  SHORT_HELP    = 'Run code in the current context'
  def run(args)
    if args.size == 1
      loc = @proc.source_location_info
      opts = {:reload_on_change => @proc.reload_on_change}
      loc, junk, text = @proc.loc_and_text(loc, opts)
      msg "eval: #{text}"
    else
      text = @proc.cmd_argstr
    end
    @proc.eval_code(text, settings[:maxstring])
  end
end

if __FILE__ == $0
  require_relative '../mock'
  dbgr, cmd = MockDebugger::setup
  arg_str = '1 + 2'
  cmd.proc.instance_variable_set('@cmd_argstr', arg_str)
  puts "eval #{arg_str} is: #{cmd.run([cmd.name, arg_str])}"
end
