# -*- coding: utf-8 -*-
# Copyright (C) 2010 Rocky Bernstein <rockyb@rubyforge.net>
require 'rubygems'; require 'require_relative'
require_relative '../../base/subsubcmd'
require_relative '../trace'
class Trepan::SubSubcommand::SetTracePrint < Trepan::SetBoolSubSubcommand
  unless defined?(HELP)
    HELP         = 
"set trace print [on|off|1|0]

Set printing trace events."

    MIN_ABBREV   = 'p'.size  
    NAME         = File.basename(__FILE__, '.rb')
    PREFIX       = %w(set trace print)
    SHORT_HELP   = 'Set print trace events'
  end

  def run(args)
    super
    if settings[:traceprint]
      @proc.unconditional_prehooks.insert_if_new(-1, *@proc.trace_hook)
    else
      @proc.unconditional_prehooks.delete_by_name('trace')
    end
  end

end

if __FILE__ == $0
  # Demo it.
  require_relative '../../../mock'
  require_relative '../../../subcmd'
  name = File.basename(__FILE__, '.rb')

  # FIXME: DRY the below code
  cmd_ary          = Trepan::SubSubcommand::SetTracePrint::PREFIX
  dbgr, parent_cmd = MockDebugger::setup(cmd_ary[0], false)
  trace_cmd        = Trepan::SubSubcommand::SetTrace.new(dbgr.processor, 
                                                         parent_cmd)
  cmd_name      = cmd_ary.join('')
  subcmd        = Trepan::SubSubcommand::SetTracePrint.new(parent_cmd.proc, 
                                                           trace_cmd,
                                                           cmd_name)
  prefix_run = cmd_ary[2..-1]
  # require_relative '../../../../lib/trepanning'
  # dbgr = Trepan.new(:set_restart => true)
  # dbgr.debugger

  subcmd.run(prefix_run)
  %w(off on 1 0).each { |arg| subcmd.run(prefix_run + [arg]) }
  puts
  puts '-' * 20
  puts subcmd.save_command()

end

