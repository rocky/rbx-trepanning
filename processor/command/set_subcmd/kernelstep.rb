# -*- coding: utf-8 -*-
# Copyright (C) 2010, 2011 Rocky Bernstein <rockyb@rubyforge.net>
require 'rubygems'; require 'require_relative'
require_relative '../show_subcmd/kernelstep'

class Trepan::Subcommand::SetKernelstep < Trepan::Subcommand::ShowKernelstep
  unless defined?(HELP)
    Trepanning::Subcommand.set_name_prefix(__FILE__, self)
    HELP         = <<-EOH
set #{NAME} [on|off]

Allow/disallow stepping into kernel methods.
    EOH

    IN_LIST      = true
    MIN_ABBREV   = 'kern'.size
    SHORT_HELP   = "Set stepping into kernel methods."
  end

  def run(args)
    onoff_arg = args.size < 3 ? 'on' : args[2]
    begin
      on = @proc.get_onoff(onoff_arg)
    rescue NameError, TypeError
      return
    end

    if on
      if ignore?
        @proc.ignore_file_re.delete(KERNEL_METHOD_FILE_RE)
      else
        errmsg("We aren't ignoring kernel methods for stepping.")
        return
      end
    else
      if ignore?
        errmsg("We already should be ignoring kernel methods for stepping.")
        return
      else
        @proc.ignore_file_re[KERNEL_METHOD_FILE_RE] = 'step-finish'
      end
    end
    show
  end

  def save_command
    PREFIX.join(' ') + (ignore? ? ' on' : ' off')
  end

end

if __FILE__ == $0
  # Demo it.
  require_relative '../../mock'
  cmd = MockDebugger::sub_setup(Trepan::Subcommand::SetKernelstep)
  cmd.run(cmd.prefix + ['off'])
  puts cmd.save_command
  cmd.run(cmd.prefix + ['on'])
  puts cmd.save_command
end
