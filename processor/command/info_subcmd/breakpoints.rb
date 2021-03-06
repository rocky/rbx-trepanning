# -*- coding: utf-8 -*-
# Copyright (C) 2010, 2011 Rocky Bernstein <rockyb@rubyforge.net>
require 'rubygems'; require 'require_relative'
require_relative '../base/subcmd'

class Trepan::Subcommand::InfoBreakpoints < Trepan::Subcommand
  unless defined?(HELP)
    Trepanning::Subcommand.set_name_prefix(__FILE__, self)
    HELP         = <<-EOH
#{PREFIX.join(' ')} [num1 ...] [verbose]

Show status of user-settable breakpoints. If no breakpoint numbers are
given, the show all breakpoints. Otherwise only those breakpoints
listed are shown and the order given. If VERBOSE is given, more
information provided about each breakpoint.

The "Disp" column contains one of "keep", "del", the disposition of
the breakpoint after it gets hit.

The "enb" column indicates whether the breakpoint is enabled.

The "Where" column indicates where the breakpoint is located.
EOH
    MIN_ABBREV   = 'br'.size
    SHORT_HELP   = 'Status of user-settable breakpoints'
  end
  
  def bpprint(bp, verbose=false)
    disp  = bp.temp?    ? 'del  ' : 'keep '
    disp += bp.enabled? ? 'y  '   : 'n  '
    msg "%-4dbreakpoint    %s at %s" % [bp.id, disp, bp.describe]
    if bp.condition && bp.condition != 'true'
      msg("\tstop %s %s" %
          [bp.negate ? "unless" : "only if", bp.condition])
    end
    if bp.hits > 0
      ss = (bp.hits > 1) ? 's' : ''
      msg("\tbreakpoint already hit %d time%s" %
          [bp.hits, ss])
    end

    if bp.ignore > 0
      msg("\tignore next %d hits" % bp.ignore)
    end
  end

  def run(args)
    verbose = false
    unless args.empty?
      if 'verbose' == args[-1]
        verbose = true
        args.pop
      end
    end


    show_all = 
      if args.size > 2
        opts = {
        :msg_on_error => 
        "An '#{PREFIX.join(' ')}' argument must eval to a breakpoint between 1..#{@proc.brkpts.max}.",
        :min_value => 1,
        :max_value => @proc.brkpts.max
      }
        bp_nums = @proc.get_int_list(args[2..-1])
        false
      else
        true
      end
    
    bpmgr = @proc.brkpts
    if bpmgr.empty? && @proc.dbgr.deferred_breakpoints.empty?
      msg('No breakpoints.')
    else
      # There's at least one
      section("Num Type          Disp Enb Where")
      bpmgr.list.each do |bp|
        bpprint(bp)
      end
      section 'Deferred breakpoints...'
      @proc.dbgr.deferred_breakpoints.each_with_index do |bp, i|
        if bp
          msg "%3d: %s" % [i+1, bp.describe]
        end
      end
    end
  end
end

if __FILE__ == $0
  # Demo it.
  require_relative '../../mock'
  name = File.basename(__FILE__, '.rb')
  dbgr, cmd = MockDebugger::setup('info')
  subcommand = Trepan::Subcommand::InfoBreakpoints.new(cmd)

  puts '-' * 20
  subcommand.run(%w(info break))
  puts '-' * 20
  subcommand.summary_help(name)
  puts
  puts '-' * 20
end
