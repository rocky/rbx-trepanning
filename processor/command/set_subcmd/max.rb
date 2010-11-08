# -*- coding: utf-8 -*-
# Copyright (C) 2010 Rocky Bernstein <rockyb@rubyforge.net>
require 'rubygems'; require 'require_relative'
require_relative '../base/subsubcmd'
require_relative '../base/subsubmgr'

class Trepan::SubSubcommand::SetMax < Trepan::SubSubcommandMgr
  HELP   = 'Set maximum length for things which may have unbounded size'
  NAME   = File.basename(__FILE__, '.rb')
  PREFIX = %W(set #{NAME})

end

if __FILE__ == $0
  # Demo it.
  require_relative '../../mock'
  cmd_ary          = Trepan::SubSubcommand::SetMax::PREFIX
  dbgr, parent_cmd = MockDebugger::setup(cmd_ary[0], false)
  cmd              = Trepan::SubSubcommand::SetMax.new(dbgr.processor, 
                                                    parent_cmd)
  cmd_name       = cmd_ary.join('')
  prefix_run = cmd_ary[1..-1]
  cmd.run(prefix_run)
  # require_relative '../../../lib/trepanning'
  # # Trepan.debug(:set_restart => true)
  ## puts cmd.summary_help(cmd.name)
  ## puts
  ## puts '-' * 20
end
