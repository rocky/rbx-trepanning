# Copyright (C) 2011 Rocky Bernstein <rockyb@rubyforge.net>
require 'rubygems'; require 'require_relative'
require_relative '../command'

class Trepan::Command::DeleteBreakpontCommand < Trepan::Command

  unless defined?(HELP)
    NAME = File.basename(__FILE__, '.rb')
    HELP = <<-HELP
#{NAME} [bpnumber [bpnumber...]]  

Delete some breakpoints.

Arguments are breakpoint numbers with spaces in between.  To delete
all breakpoints, give no argument.  those breakpoints.  Without
argument, clear all breaks (but first ask confirmation).
    
See also the "clear" command which clears breakpoints by line/file
number.
    HELP

    CATEGORY      = 'breakpoints'
    SHORT_HELP    = 'Delete some breakpoints'
  end

  def run(args)
    if args.size == 1
      if confirm('Delete all breakpoints?', false)
        @proc.brkpts.reset
        return
      end
    end
    first = args.shift
    args.each do |num_str|
      opts = {:msg_on_error => '%s must be a number' % num_str}
      i = @proc.get_an_int(num_str, opts)
      if i 
        success = @proc.delete_breakpoint_by_number(num_str.to_i, false) if i
        msg('Deleted breakpoint %d.' % i) if success
      end
    end
  end
end

