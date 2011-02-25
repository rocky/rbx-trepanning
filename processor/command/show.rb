# -*- coding: utf-8 -*-
# Copyright (C) 2010, 2011 Rocky Bernstein <rockyb@rubyforge.net>
require 'rubygems'; require 'require_relative'
require_relative 'base/submgr'

class Trepan::Command::ShowCommand < Trepan::SubcommandMgr
  unless defined?(HELP)
    NAME = File.basename(__FILE__, '.rb')
    HELP = <<-HELP
Generic command for showing things about the debugger.  You can
give unique prefix of the name of a subcommand to get information
about just that subcommand.

Type "#{NAME}" for a list of "show" subcommands and what they do.
Type "help #{NAME} *" for just a list of "show" subcommands.
    HELP

    CATEGORY      = 'status'
    NEED_STACK    = false
    SHORT_HELP    = 'Show parts of the debugger environment'
  end

  def run(args)
    if args.size > 1 
      first = args[1].downcase
      alen = 'auto'.size
      args[1..1] = ['auto', first[alen..-1]] if
        first.start_with?('auto') && first.size > alen
    end
    super
  end

end

if __FILE__ == $0
  require_relative '../mock'
  dbgr, cmd = MockDebugger::setup
  cmd.run([cmd.name])
end
