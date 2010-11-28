# -*- coding: utf-8 -*-
# Copyright (C) 2010 Rocky Bernstein <rockyb@rubyforge.net>
require 'rubygems'; require 'require_relative'
require_relative '../../base/subsubcmd'

class Trepan::SubSubcommand::SetDebugSkip < Trepan::SetBoolSubSubcommand
  unless defined?(HELP)
    HELP        = 'Set debugging of statement skip logic'
    MIN_ABBREV  = 'sk'.size
    NAME        = File.basename(__FILE__, '.rb')
    PREFIX      = %W(set debug #{NAME})
  end
end

if __FILE__ == $0
  # Demo it.
  require_relative '../../../mock'
  require_relative '../../../subcmd'

  # FIXME: DRY the below code
  dbgr, dbg_cmd  = MockDebugger::setup('set', false)
  debug_cmd      = Trepan::SubSubcommand::SetDebug.new(dbgr.processor, dbg_cmd)
  # FIXME: remove the 'join' below
  cmd_name       = Trepan::SubSubcommand::SetDebugSkip::PREFIX.join('')
  debugx_cmd     = Trepan::SubSubcommand::SetDebugSkip.new(dbg_cmd.proc, 
                                                           debug_cmd,
                                                           cmd_name)
  # # require_relative '../../../../lib/trepanning'
  # # dbgr = Trepan.new(:set_restart => true)
  # # dbgr.debugger
  debugx_cmd.run([debugx_cmd.name])
  debugx_cmd.run([debugx_cmd.name, 'on'])
  debugx_cmd.run([debugx_cmd.name, 'off'])
end
