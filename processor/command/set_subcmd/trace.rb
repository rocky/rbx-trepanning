# -*- coding: utf-8 -*-
# Copyright (C) 2010 Rocky Bernstein <rockyb@rubyforge.net>
require 'rubygems'; require 'require_relative'
require_relative '../base/subsubcmd'
require_relative '../base/subsubmgr'

class Trepan::SubSubcommand::SetTrace < Trepan::SubSubcommandMgr 
  unless defined?(HELP)
    HELP = "Set tracing of various sorts.

The types of tracing include global variables, events from the trace
buffer, or printing those events.

See 'help set trace *' or a list of subcommands or 'help set trace
<name>' for help on a particular trace subcommand."

    IN_LIST    = true
    MIN_ABBREV = 'tr'.size
    NAME       = File.basename(__FILE__, '.rb')
    PREFIX     = %W(set #{NAME})
    SHORT_HELP = 'Set tracing of various sorts.'
  end

end

if __FILE__ == $0
  # Demo it.
  require_relative '../../mock'
  cmd_ary          = Trepan::SubSubcommand::SetTrace::PREFIX
  dbgr, parent_cmd = MockDebugger::setup(cmd_ary[0], false)
  command = Trepan::SubSubcommand::SetTrace.new(dbgr.processor, 
                                                parent_cmd)
  # require_relative '../../../lib/trepanning'
  # Trepan.debug(:set_restart => true)
  command.run(cmd_ary)
  command.run(['set', command.name, 'print'])
end
