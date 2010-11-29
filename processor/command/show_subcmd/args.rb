# -*- coding: utf-8 -*-
# Copyright (C) 2010 Rocky Bernstein <rockyb@rubyforge.net>
require 'rubygems'; require 'require_relative'
require_relative '../base/subcmd'

class Trepan::Subcommand::ShowArgs < Trepan::Subcommand
  unless defined?(HELP)
    NAME         = File.basename(__FILE__, '.rb')
    HELP = 'Show argument list to give program when it is restarted'
    MIN_ABBREV   = 'ar'.size
    PREFIX       = %W(show #{NAME})
  end

  def run(args)
    dbgr = @proc.dbgr
    msg "Restart directory: #{Rubinius::OS_STARTUP_DIR}"
    msg "Restart args:\n\t#{dbgr.restart_argv.inspect}"
  end
    
end

if __FILE__ == $0
  # Demo it.
  require_relative '../../mock'
  cmd = MockDebugger::sub_setup(Trepan::Subcommand::ShowArgs)
end
