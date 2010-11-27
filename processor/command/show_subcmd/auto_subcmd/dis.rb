# -*- coding: utf-8 -*-
# Copyright (C) 2010 Rocky Bernstein <rockyb@rubyforge.net>
require 'rubygems'; require 'require_relative'
require_relative '../../base/subsubcmd'

class Trepan::SubSubcommand::ShowAutoDis < Trepan::ShowBoolSubSubcommand
  unless defined?(HELP)
    HELP = "Show running a 'dis' command each time we enter the debugger"
    MIN_ABBREV   = 'l'.size
    NAME         = File.basename(__FILE__, '.rb')
    PREFIX       = %w(show auto dis)
  end

end

if __FILE__ == $0
  # Demo it.
  require_relative '../../../mock'
  require_relative '../../../subcmd'

  # FIXME: DRY the below code

  dbgr, show_cmd = MockDebugger::setup('show', false)
  testcmdMgr     = Trepan::Subcmd.new(show_cmd)
  auto_cmd       = Trepan::SubSubcommand::ShowAuto.new(dbgr.processor, 
                                                       show_cmd)

  # FIXME: remove the 'join' below
  cmd_name       = Trepan::SubSubcommand::ShowAutoDis::PREFIX.join('')
  autox_cmd      = Trepan::SubSubcommand::ShowAutoDis.new(show_cmd.proc, auto_cmd,
                                                           cmd_name)
  # require_relative '../../../../lib/trepanning'
  # dbgr = Trepan.new(:set_restart => true)
  # dbgr.debugger
  autox_cmd.run([])

end
