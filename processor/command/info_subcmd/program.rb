# -*- coding: utf-8 -*-
# Copyright (C) 2010 Rocky Bernstein <rockyb@rubyforge.net>
require 'rubygems'; require 'require_relative'
require_relative '../base/subcmd'

class Trepan::Subcommand::InfoProgram < Trepan::Subcommand
  unless defined?(HELP)
    HELP         = 'Information about debugged program and its environment'
    MIN_ABBREV   = 'pr'.size
    NAME         = File.basename(__FILE__, '.rb')
    NEED_STACK   = true
    PREFIX       = %w(info program)
  end

  def run(args)
    frame = @proc.frame
    ## m = 'Program stop event: %s' % @proc.core.event
    m = ''
    m += 
      if frame.method
        "PC offset %d of method: %s" %
          [frame.ip, frame.method.name]
      else
        ## '.'
      end
    msg m
    # if 'return' == @proc.core.event 
    #   msg 'R=> %s' % @proc.frame.sp(1).inspect 
    # elsif 'raise' == @proc.core.event
    #   msg @proc.core.hook_arg.inspect if @proc.core.hook_arg
    # end

    if @proc.brkpt
      msg('It is stopped at %sbreakpoint %d.' %
          [@proc.brkpt.temp? ? 'temporary ' : '',
           @proc.brkpt.id])
    end
  end

end

if __FILE__ == $0
  # Demo it.
  require_relative '../../mock'
  name = File.basename(__FILE__, '.rb')

  # FIXME: DRY the below code
  dbgr, cmd = MockDebugger::setup('info')
  subcommand = Trepan::Subcommand::InfoProgram.new(cmd)
  testcmdMgr = Trepan::Subcmd.new(subcommand)

  subcommand.run_show_bool
  name = File.basename(__FILE__, '.rb')
  subcommand.summary_help(name)
  puts
end
