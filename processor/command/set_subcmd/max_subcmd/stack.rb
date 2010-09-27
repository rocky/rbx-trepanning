# -*- coding: utf-8 -*-
# Copyright (C) 2010 Rocky Bernstein <rockyb@rubyforge.net>
require 'rubygems'; require 'require_relative'
require_relative '../../base/subsubcmd'

class Trepan::Subcommand::SetMaxStack < Trepan::SubSubcommand
  unless defined?(HELP)
    HELP         = 'Set number of backtrace lines the debugger will show'
    DEFAULT_MIN  = 3
    MIN_ABBREV   = 'sta'.size
    NAME         = File.basename(__FILE__, '.rb')
    PREFIX       = %w(set max stack)
  end

  def run(args)
    args.shift
    args = %W(#{DEFAULT_MIN}) if args.empty?
    run_set_int(args.join(' '),
                "The '#{PREFIX.join(' ')}' command requires a list size", 
                DEFAULT_MIN, nil)
  end

  alias save_command save_command_from_settings

end

if __FILE__ == $0
  # Demo it.
  require_relative '../../../mock'
  dbgr, set_cmd = MockDebugger::setup('set')
  name = File.basename(__FILE__, '.rb')

  dbgr, set_cmd = MockDebugger::setup('set')
  max_cmd       = Trepan::SubSubcommand::SetMax.new(dbgr.processor, 
                                                      set_cmd)
  cmd_ary       = Trepan::SubSubcommand::SetMaxStack::PREFIX
  cmd_name      = cmd_ary.join('')
  subcmd        = Trepan::SubSubcommand::SetMaxStack.new(set_cmd.proc,
                                                         max_cmd,
                                                         cmd_name)
  prefix_run = cmd_ary[1..-1]
  subcmd.run(prefix_run)
  subcmd.run(prefix_run + %w(0))
  subcmd.run(prefix_run + %w(20))
  name = File.basename(__FILE__, '.rb')
  subcmd.summary_help(name)
  puts
  puts '-' * 20
  puts subcmd.save_command
end
