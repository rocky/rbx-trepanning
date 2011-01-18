# -*- coding: utf-8 -*-
# Copyright (C) 2010, 2011 Rocky Bernstein <rockyb@rubyforge.net>
require 'rubygems'; require 'require_relative'
require_relative '../base/subsubcmd'
require_relative '../base/subsubmgr'

class Trepan::SubSubcommand::SetAuto < Trepan::SubSubcommandMgr
  unless defined?(HELP)
    HELP   = 'Set controls for things with some sort of "automatic" default behavior'
    Trepanning::Subcommand.set_name_prefix(__FILE__, self)
  end
end

if __FILE__ == $0
  require_relative '../../mock'
  dbgr, cmd = MockDebugger::setup('set')
  # cmds = dbgr.core.processor.commands
  # set_cmd = cmds['set']
  # command = Trepan::SubSubcommand::SetAuto.new(dbgr.core.processor, 
  #                                              set_cmd)
  # name = File.basename(__FILE__, '.rb')
  # cmd_args = ['set', name]
  # set_cmd.instance_variable_set('@last_args', cmd_args)
  # # require_relative '../../../lib/trepanning'
  # # Trepan.debug(:set_restart => true)
  # command.run(cmd_args)
end
