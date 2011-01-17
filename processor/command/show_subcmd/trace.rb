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
  cmd_ary          = Trepan::SubSubcommand::ShowTrace::PREFIX
  dbgr, parent_cmd = MockDebugger::setup(cmd_ary[0], false)
  cmd              = Trepan::SubSubcommand::ShowTrace.new(dbgr.processor, 
                                                          parent_cmd)
  cmd_name       = cmd_ary.join('')
  prefix_run = cmd_ary[1..-1]
  cmd.run(prefix_run)
end
