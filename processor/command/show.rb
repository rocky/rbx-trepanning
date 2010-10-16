# -*- coding: utf-8 -*-
# Copyright (C) 2010 Rocky Bernstein <rockyb@rubyforge.net>
require 'rubygems'; require 'require_relative'
require_relative 'base/submgr'

class Trepan::Command::ShowCommand < Trepan::SubcommandMgr
  unless defined?(HELP)
    HELP =
'Generic command for showing things about the debugger.  You can
give unique prefix of the name of a subcommand to get information
about just that subcommand.

Type "show" for a list of "show" subcommands and what they do.
Type "help show *" for just a list of "show" subcommands.'

    CATEGORY      = 'status'
    NAME          = File.basename(__FILE__, '.rb')
    NEED_STACK    = false
    SHORT_HELP    = 'Show parts of the debugger environment'
  end
end

if __FILE__ == $0
  require_relative '../mock'
  name = File.basename(__FILE__, '.rb')
  dbgr, cmd = MockDebugger::setup(name)
  cmd.run([cmd.name])
end
