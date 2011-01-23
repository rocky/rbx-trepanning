# -*- coding: utf-8 -*-
# Copyright (C) 2010, 2011 Rocky Bernstein <rockyb@rubyforge.net>
require 'rubygems'; require 'require_relative'
require_relative 'base/cmd'
require_relative '../eval'
class Trepan::Command::PsCommand < Trepan::Command

  unless defined?(HELP)
    HELP = 
      "ps ARRAY

Print the value of the ARRAY in columns and sorted."

    CATEGORY      = 'data'
    MIN_ARGS      = 1  # Need least this many
    NAME          = File.basename(__FILE__, '.rb')
    SHORT_HELP    = 'Print array sorted and in columns'
  end
  
  def run(args)
    array = @proc.debug_eval(@proc.cmd_argstr, settings[:maxstring])
    # FIXME: should test for enumerable
    if array.is_a?(Array)
      msg columnize_commands(array.sort)
    else
      errmsg "ps: #{@proc.cmd_argstr} should evaluate an Array not #{array.class}"
    end
  end
end
        
if __FILE__ == $0
  require_relative '../mock'
  dbgr, cmd = MockDebugger::setup
  arg_str = '(1..30).to_a'
  cmd.proc.instance_variable_set('@cmd_argstr', arg_str)
  cmd.run([cmd.name, arg_str])
  arg_str = '1'
  cmd.proc.instance_variable_set('@cmd_argstr', arg_str)
  cmd.run([cmd.name, arg_str])
end
