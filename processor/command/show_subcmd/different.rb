# -*- coding: utf-8 -*-
# Copyright (C) 2010 Rocky Bernstein <rockyb@rubyforge.net>
require 'rubygems'; require 'require_relative'
require_relative '../base/subcmd'

class Trepan::Subcommand::ShowDifferent < Trepan::ShowBoolSubcommand
  unless defined?(HELP)
    HELP         = "Show status of 'set different'"
    MIN_ABBREV   = 'dif'.size
    PREFIX       = %w(show different)
    NAME         = File.basename(__FILE__, '.rb')
  end

  def run(args)
    if 'nostack' == @proc.settings[:different]
      msg "%s is nostack." % HELP[5..-1].capitalize
    else
      super
    end
  end


end

if __FILE__ == $0
  # Demo it.
  require_relative '../../mock'

  # FIXME: DRY the below code
  dbgr, cmd = MockDebugger::setup('show')
  subcommand = Trepan::Subcommand::ShowDifferent.new(cmd)

  subcommand.run(cmd.name)
  [true, false].each do |val|
    subcommand.proc.settings[:different] = val
    subcommand.run(cmd.name)
  end
  subcommand.summary_help(cmd.name)
  puts
  puts '-' * 20
end
