# -*- coding: utf-8 -*-
# Copyright (C) 2010, 2011 Rocky Bernstein <rockyb@rubyforge.net>
require 'rubygems'; require 'require_relative'
require_relative '../base/subsubcmd'
require_relative '../base/subsubmgr'

class Trepan::SubSubcommand::ShowTrace < Trepan::SubSubcommandMgr 

  unless defined?(HELP)
    HELP = "Show event tracing printing"
    NAME       = File.basename(__FILE__, '.rb')
    PREFIX     = %W(show #{NAME})
    MIN_ABBREV = 'tr'.size
    SHORT_HELP = HELP
  end
end

if __FILE__ == $0
  # Demo it.
  require_relative '../../mock'
  parent_cmd = File.dirname(__FILE__)[0...-('_subcmd'.size)]
  dbgr, cmd = MockDebugger::setup(parent_cmd, false)
  command = Trepan::SubSubcommand::ShowTrace.new(dbgr.processor, 
                                                 cmds[parent_cmd])
  name = File.basename(__FILE__, '.rb')
  cmd_args = [parent_cmd, name]
  command.run(cmd_args)
end
