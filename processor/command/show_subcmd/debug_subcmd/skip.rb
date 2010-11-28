# -*- coding: utf-8 -*-
# Copyright (C) 2010 Rocky Bernstein <rockyb@rubyforge.net>
require 'rubygems'; require 'require_relative'
require_relative '../../base/subsubcmd'

class Trepan::SubSubcommand::ShowDebugSkip < Trepan::ShowBoolSubSubcommand
  unless defined?(HELP)
    HELP        = 'Show debugging of statement skip logic'
    MIN_ABBREV  = 'st'.size
    NAME        = File.basename(__FILE__, '.rb')
    PREFIX      = %W(show debug #{NAME})
  end

end

if __FILE__ == $0
  # Demo it.
  require_relative '../../../mock'

  # FIXME: DRY the below code
  dbgr, show_cmd  = MockDebugger::setup('show')
  debug_cmd       = Trepan::SubSubcommand::ShowDebug.new(dbgr.processor, 
                                                         show_cmd)

  # FIXME: remove the 'join' below
  cmd_name        = Trepan::SubSubcommand::ShowDebugSkip::PREFIX.join('')
  debugx_cmd      = Trepan::SubSubcommand::ShowDebugSkip.new(show_cmd.proc, 
                                                             debug_cmd,
                                                             cmd_name)

  debugx_cmd.run([])
end
