# -*- coding: utf-8 -*-
# Copyright (C) 2010, 2011 Rocky Bernstein <rockyb@rubyforge.net>
require 'rubygems'; require 'require_relative'
require_relative '../base/subsubcmd'
require_relative '../base/subsubmgr'

class Trepan::SubSubcommand::SetMax < Trepan::SubSubcommandMgr
  Trepanning::Subcommand.set_name_prefix(__FILE__, self)
  HELP   = 'Set maximum length for things which may have unbounded size'
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
  # require 'trepanning'; debugger
  %w(s lis foo).each do |prefix|
    p [prefix, cmd.complete(prefix)]
  end
end
