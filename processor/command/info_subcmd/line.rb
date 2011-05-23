# -*- coding: utf-8 -*-
# Copyright (C) 2011 Rocky Bernstein <rockyb@rubyforge.net>
require 'rubygems'; require 'require_relative'
require_relative '../base/subcmd'
require_relative '../../../app/iseq'


class Trepan::Subcommand::InfoLine < Trepan::Subcommand
  unless defined?(HELP)
    Trepanning::Subcommand.set_name_prefix(__FILE__, self)
    HELP = <<-EOH
#{CMD} [LINE-NUMBER]

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

  include Trepan::ISeq

  def run(args)
    frame = @proc.frame
    vm_location = frame.vm_location
    cm          = frame.method
    filename    = cm.file
    lines       = cm.lines
    tail_code   = false
    if args.size == 2
      line_no     = vm_location.line
      if line_no == 0
        tail_code = true
        line_no = frame.line
      end
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
    ranges, prefix = 
      if tail_code
        [ip_ranges_for_ip(lines, frame.next_ip), 'Tail code preceding line']
      else
        [ip_ranges_for_line(lines, line_no), 'Line']
      end
    if ranges.empty?
      msg "%s %s of %s:\n\tno bytecode offsets" % [prefix, line_no, filename]
    else
      msg "%s %s of %s:" % [prefix, line_no, filename]
      ranges.each do |tuple|
        msg "\t starts at offset %d and ends before offset %d" % tuple
      end
    end
  end

end

if __FILE__ == $0
  # Demo it.
  require_relative '../../mock'
  cmd = MockDebugger::sub_setup(Trepan::Subcommand::InfoLine, false)
  cmd.run(cmd.prefix)
end
