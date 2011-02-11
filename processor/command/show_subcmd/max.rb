# -*- coding: utf-8 -*-
# Copyright (C) 2010, 2011 Rocky Bernstein <rockyb@rubyforge.net>
require 'rubygems'; require 'require_relative'
require_relative '../base/subsubcmd'
require_relative '../base/subsubmgr'

class Trepan::SubSubcommand::ShowMax < Trepan::SubSubcommandMgr
  unless defined?(HELP)
    Trepanning::Subcommand.set_name_prefix(__FILE__, self)
    HELP   = 'Show "maximum length" settings'
  end

  def run(args)
    super
  end
end

if __FILE__ == $0
  require_relative '../../mock'
  cmd_ary          = Trepan::SubSubcommand::ShowMax::PREFIX
  dbgr, parent_cmd = MockDebugger::setup(cmd_ary[0], false)
  cmd              = Trepan::SubSubcommand::ShowMax.new(dbgr.processor, 
                                                        parent_cmd)
  cmd_name       = cmd_ary.join('')
  prefix_run = cmd_ary[1..-1]
  cmd.run(prefix_run)
end
