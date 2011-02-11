# -*- coding: utf-8 -*-
# Copyright (C) 2010, 2011 Rocky Bernstein <rockyb@rubyforge.net>
require 'rubygems'; require 'require_relative'
require_relative '../base/subcmd'

class Trepan::Subcommand::InfoProgram < Trepan::Subcommand
  unless defined?(HELP)
    Trepanning::Subcommand.set_name_prefix(__FILE__, self)
    HELP         = 'Information about debugged program and its environment'
    MIN_ABBREV   = 'pr'.size
    NEED_STACK   = true
   end

  def run(args)
    frame = @proc.frame
    ## m = 'Program stop event: %s' % @proc.core.event
    m = ''
    m += "Frame index #{@proc.frame_index}, " if @proc.frame_index != 0
    m += 
      if frame.method
        "PC offset %d of method: %s" %
          [frame.next_ip, frame.method.name]
      else
        ## '.'
      end
    msg m
    # if 'return' == @proc.core.event 
    #   msg 'R=> %s' % @proc.frame.sp(1).inspect 
    # elsif 'raise' == @proc.core.event
    #   msg @proc.core.hook_arg.inspect if @proc.core.hook_arg
    # end

    if @proc.brkpt && @proc.brkpt.event == :Breakpoint
      msg('It stopped at %sbreakpoint %d.' %
          [@proc.brkpt.temp? ? 'temporary ' : '',
           @proc.brkpt.id])
    else
      msg("Program stopped at a #{@proc.event} event.")
    end
  end

end

if __FILE__ == $0
  # Demo it.
  require_relative '../../mock'
  cmd = MockDebugger::sub_setup(Trepan::Subcommand::InfoProgram, false)
  cmd.run(cmd.prefix)
end
