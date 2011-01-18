# -*- coding: utf-8 -*-
# Copyright (C) 2010, 2011 Rocky Bernstein <rockyb@rubyforge.net>
require 'rubygems'; require 'require_relative'
require_relative '../base/subcmd'

class Trepan::Subcommand::ShowDifferent < Trepan::ShowBoolSubcommand
  unless defined?(HELP)
    Trepanning::Subcommand.set_name_prefix(__FILE__, self)
    HELP         = "Show status of 'set different'"
    MIN_ABBREV   = 'dif'.size
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
  cmd = MockDebugger::sub_setup(Trepan::Subcommand::ShowDifferent)
end
