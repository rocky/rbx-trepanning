# -*- coding: utf-8 -*-
# Copyright (C) 2010, 2011 Rocky Bernstein <rockyb@rubyforge.net>
require 'rubygems'; require 'require_relative'
require_relative '../base/subcmd'

class Trepan::Command::InfoVariables < Trepan::Subcommand
  Trepanning::Subcommand.set_name_prefix(__FILE__, self)
  MIN_ABBREV   = 'var'.size
  NEED_STACK   = true
  SHORT_HELP   = 'Display the value of a variable or variables'
  HELP         = <<-HELP
Show debugger variables and user created variables. By default,
shows all variables.

The optional argument is which variable specifically to show the value of.
      HELP
  
  def run(args)
    if args.size == 2
      @proc.dbgr.variables.each do |name, val|
        msg "var '#{name}' = #{val.inspect}"
      end
      
      if @proc.dbgr.user_variables > 0
        section "User variables"
        (0...@proc.dbgr.user_variables).each do |i|
          str = "$d#{i}"
          val = Rubinius::Globals[str.to_sym]
          msg "var #{str} = #{val.inspect}"
        end
      end
    else
      var = args[2]
      if @proc.dbgr.variables.key?(var)
        msg "var '#{var}' = #{variables[var].inspect}"
      else
        errmsg "No variable set named '#{var}'"
      end
    end
  end
end

if __FILE__ == $0
  # Demo it.
  require_relative '../../mock'
  cmd = MockDebugger::sub_setup(Trepan::Subcommand::InfoVariables, false)
  # cmd.run(cmd.prefix)
end
