# -*- coding: utf-8 -*-
# Copyright (C) 2010 Rocky Bernstein <rockyb@rubyforge.net>
require 'rubygems'; require 'require_relative'
require_relative '../../base/subsubcmd'

class Trepan::SubSubcommand::ShowMaxList < Trepan::ShowIntSubSubcommand
  unless defined?(HELP)
    HELP = 'Show the number of source file lines to list'
    MIN_ABBREV   = 'lis'.size
    NAME         = File.basename(__FILE__, '.rb')
    PREFIX       = %w(show max list)
  end

end

if __FILE__ == $0
  # Demo it.
  require_relative '../../../mock'

  # FIXME: DRY the below code
  cmd_ary          = Trepan::SubSubcommand::ShowMaxList::PREFIX
  dbgr, parent_cmd = MockDebugger::setup(cmd_ary[0], false)
  cmd              = Trepan::SubSubcommand::ShowMax.new(dbgr.processor, 
                                                        parent_cmd)
  cmd_name       = cmd_ary.join('')
  subcmd         = Trepan::SubSubcommand::ShowMaxList.new(parent_cmd.proc,
                                                          cmd,
                                                          cmd.name)
  prefix_run = cmd_ary[1..-1]
  subcmd.run(prefix_run)
  
  # require_relative '../../../../lib/trepanning'
  # dbgr = Trepan.new(:set_restart => true)
  # dbgr.debugger
  puts subcmd.summary_help(cmd.name)
  puts
  puts '-' * 20
end
