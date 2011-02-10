# -*- coding: utf-8 -*-
# Copyright (C) 2011 Rocky Bernstein <rockyb@rubyforge.net>
require 'rubygems'; require 'require_relative'
require_relative '../base/subcmd'

class Trepan::Subcommand::InfoLine < Trepan::Subcommand
  unless defined?(HELP)
    Trepanning::Subcommand.set_name_prefix(__FILE__, self)
    HELP = <<-EOH
#{CMD=PREFIX.join(' ')} [LINE-NUMBER]

Show bytecode offset for LINE-NUMBER. If no LINE-NUMBER is given, 
then we use the current line that we are stopped in.

Examples:
#{CMD} 
#{CMD} 10
    EOH
    MIN_ABBREV   = 'li'.size
    NEED_STACK   = true
    SHORT_HELP   = 'Byte code offsets for source code line'
   end

  def ip_ranges_for_line(lines, line)
    result = []
    in_range = false
    start_ip = nil
    total = lines.size
    i = 1
    while i < total
      cur_line = lines.at(i)
      if cur_line == line
        start_ip = lines.at(i-1)
        in_range = true
      elsif cur_line > line && in_range
        result << [start_ip, lines.at(i-1)]
        start_ip = nil
        in_range = false
      end
      i += 2
    end
    if in_range && start_ip
      result << [start_ip, lines.at(total-1)]
    end
    result
  end
  
  def run(args)
    frame = @proc.frame
    vm_location = frame.vm_location
    cm          = frame.method
    filename    = cm.file
    lines       = cm.lines
    if args.size == 2
      line_no     = vm_location.line
    else
      lineno_str = args[2]
      opts = {
        :msg_on_error =>
        "The 'info line' line number must be an integer. Got: %s" % lineno_str,
        :min_value => lines.at(1),
        :max_value => lines.at(lines.size-2)
      }
      line_no = @proc.get_an_int(lineno_str, opts)
      return false unless line_no
    end
      
    ranges      = ip_ranges_for_line(lines, line_no)
    if ranges.empty?
      msg "Line %s of %s:\n\tno bytecode offsets" % [line_no, filename]
    else
      msg "Line %s of %s:" % [line_no, filename]
      ranges.each do |tuple|
        msg "\t starts at offset %d and ends before offset %d" % tuple
      end
    end
  end

end

if __FILE__ == $0
  # Demo it.
  require_relative '../../mock'
  name = File.basename(__FILE__, '.rb')
  dbgr, cmd = MockDebugger::setup('info')
  subcommand = Trepan::Subcommand::InfoLine.new(cmd)
end
