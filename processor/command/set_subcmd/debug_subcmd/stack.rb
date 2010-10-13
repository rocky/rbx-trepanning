# -*- coding: utf-8 -*-
# Copyright (C) 2010 Rocky Bernstein <rockyb@rubyforge.net>
require 'rubygems'; require 'require_relative'
require_relative '../../base/subsubcmd'

class Trepan::SubSubcommand::SetDebugStack < Trepan::SetBoolSubSubcommand
  unless defined?(HELP)
    HELP = "Set display of complete stack including possibly setup stack from trepanning"
    MIN_ABBREV  = 'st'.size
    NAME        = File.basename(__FILE__, '.rb')
    PREFIX      = %W(set debug #{NAME})
  end

  def run(args)
    super
    @proc.hide_level  = 
      if @proc.settings[:debugstack]
        0
      else
        @proc.hidelevels[@proc.current_thread] || 0
      end
    @proc.stack_size = @proc.dbgr.locations.size - @proc.hide_level
  end
end

if __FILE__ == $0
  # Demo it.
  require_relative '../../../mock'
  name = File.basename(__FILE__, '.rb')

  # FIXME: DRY the below code
  dbgr, set_cmd  = MockDebugger::setup('set')
  # debug_cmd      = Trepan::SubSubcommand::SetDebug.new(dbgr.core.processor, 
  #                                                       set_cmd)
  # # FIXME: remove the 'join' below
  # cmd_name       = Trepan::SubSubcommand::SetDebugStack::PREFIX.join('')
  # debugx_cmd     = Trepan::SubSubcommand::SetDebugStack.new(set_cmd.proc, 
  #                                                             debug_cmd,
  #                                                             cmd_name)
  # # require_relative '../../../../lib/trepanning'
  # # dbgr = Trepan.new(:set_restart => true)
  # # dbgr.debugger
  # debugx_cmd.run([name])
  # debugx_cmd.run([name, 'off'])
  # debugx_cmd.run([name, 'on'])
end
