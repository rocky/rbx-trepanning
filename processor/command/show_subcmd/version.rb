# -*- coding: utf-8 -*-
# Copyright (C) 2010, 2011 Rocky Bernstein <rockyb@rubyforge.net>
require 'rubygems'; require 'require_relative'
require_relative '../../../app/options'
require_relative '../base/subcmd'

class Trepan::Subcommand::ShowVersion < Trepan::Subcommand
  unless defined?(HELP)
    Trepanning::Subcommand.set_name_prefix(__FILE__, self)
    HELP         = "Show what version of #{Trepan::PROGRAM} this is"
    MIN_ABBREV   = 'vers'.size
  end

  def run(args)
    msg Trepan::show_version
  end
end

if __FILE__ == $0
  # Demo it.
  require_relative '../../mock'
  cmd = MockDebugger::sub_setup(Trepan::Subcommand::ShowVersion)
end
