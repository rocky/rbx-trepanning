# -*- coding: utf-8 -*-
# Copyright (C) 2010 Rocky Bernstein <rockyb@rubyforge.net>
require 'rubygems'; require 'require_relative'
require_relative '../base/subcmd'

class Trepan::Subcommand::ShowKernelstep < Trepan::Subcommand
  unless defined?(HELP)
    NAME         = File.basename(__FILE__, '.rb')
    HELP       = "Show stepping into kernel methods"

    IN_LIST      = true
    MIN_ABBREV   = 'kern'.size

    # FIXME: DRY setting NAME and PREFIX
    NAME       = File.basename(__FILE__, '.rb')
    dirname    = File.basename(File.dirname(File.expand_path(__FILE__)))
    PREFIX     = %W(#{dirname[0...-'_subcmd'.size]}
                    #{NAME})

    # Specific to this class
    KERNEL_METHOD_FILE_RE    = /^kernel\//
  end

  def ignore?
    @proc.ignore_file_re.member?(KERNEL_METHOD_FILE_RE)
  end

  def show
    msg("stepping into kernel methods is %s." % 
        (ignore? ? 'disallowed' : 'allowed'))
  end

  def run(args)
    show
  end
end

if __FILE__ == $0
  # Demo it.
  require_relative '../../mock'
  cmd = MockDebugger::sub_setup(Trepan::Subcommand::ShowKernelstep)
end
