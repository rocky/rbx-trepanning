# -*- coding: utf-8 -*-
# Copyright (C) 2011 Rocky Bernstein <rockyb@rubyforge.net>
require 'rubygems'; require 'require_relative'
require 'pp'
require_relative 'base/cmd'
require_relative '../../app/cmd_parse'
class Trepan::Command::ParseTreeCommand < Trepan::Command
  
  unless defined?(HELP)
    NAME = File.basename(__FILE__, '.rb')
    HELP = <<-HELP
#{NAME} [FILE]
#{NAME} 

In the first form, print a ParseTree S-expression of the current file
or FILE.
HELP
      
    # ALIASES       = %w(p)
    MAX_ARGS      = 1
    CATEGORY      = 'data'
    SHORT_HELP    = 'PrettyPrint a ParseTree S-expression for a file'
  end
  
  def run(args)
    meth = nil
    case args.size
    when 1
      file = @proc.frame.file
    when 2
      file = args[1]
    else
      errmsg 'Expecting a file name'
    end
    expanded_file = File.expand_path(file)
    if File.readable?(expanded_file)
      msg File.to_sexp(expanded_file).pretty_inspect
    else
      errmsg "File #{File} is not readable."
    end
  end
  
  if __FILE__ == $0
    require 'pp'
    require_relative '../mock'
    dbgr, cmd = MockDebugger::setup
    cmd.run([cmd.name, __FILE__])
  end
  
end
