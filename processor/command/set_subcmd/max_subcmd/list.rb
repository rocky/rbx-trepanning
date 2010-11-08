# -*- coding: utf-8 -*-
# Copyright (C) 2010 Rocky Bernstein <rockyb@rubyforge.net>
require 'rubygems'; require 'require_relative'
require_relative '../../base/subsubcmd'

class Trepan::SubSubcommand::SetMaxList < Trepan::SubSubcommand
  unless defined?(HELP)
    HELP         = 'Set max[imum] list NUMBER

Set number of source-code lines to list by default.'
    IN_LIST      = true
    MIN_ABBREV   = 'lis'.size
    NAME         = File.basename(__FILE__, '.rb')
    PREFIX       = %w(set max list)
    SHORT_HELP   = 'Set number of lines to list'
  end

  def run(args)
    args.shift
    run_set_int(args.join(' '),
                "The '#{PREFIX.join(' ')}' command requires a list size", 
                0, nil)
  end

  alias save_command save_command_from_settings

end

if __FILE__ == $0
  # Demo it.
  require_relative '../../../mock'

  dbgr, set_cmd = MockDebugger::setup('set', false)
  max_cmd       = Trepan::SubSubcommand::SetMax.new(dbgr.processor, 
                                                      set_cmd)
  cmd_ary       = Trepan::SubSubcommand::SetMaxWidth::PREFIX
  cmd_name      = cmd_ary.join('')
  subcmd        = Trepan::SubSubcommand::SetMaxList.new(set_cmd.proc,
                                                        max_cmd,
                                                        cmd_name)
  prefix_run = cmd_ary[1..-1]
  subcmd.run(prefix_run)
  subcmd.run(prefix_run + %w(0))
  subcmd.run(prefix_run + %w(20))
  subcmd.summary_help(subcmd.name)
  puts
  puts '-' * 20
  puts subcmd.save_command
end
