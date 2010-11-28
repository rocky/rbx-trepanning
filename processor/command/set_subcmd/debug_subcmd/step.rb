# -*- coding: utf-8 -*-
# Copyright (C) 2010 Rocky Bernstein <rockyb@rubyforge.net>
require 'rubygems'; require 'require_relative'
require_relative '../../base/subsubcmd'

class Trepan::SubSubcommand::SetDebugStep < Trepan::SetBoolSubSubcommand
  unless defined?(HELP)
    HELP        = 'Set debugging of statement step logic'
    MIN_ABBREV  = 'st'.size
    NAME        = File.basename(__FILE__, '.rb')
    PREFIX      = %W(set debug #{NAME})
  end
end

if __FILE__ == $0
  # Demo it.
  require_relative '../../../mock'
  require_relative '../debug'
  cmd = MockDebugger::subsub_setup(Trepan::SubSubcommand::SetDebug,
                                   Trepan::SubSubcommand::SetDebugStep)
  cmd.run([cmd.name, 'off'])
  cmd.run([cmd.name, 'on'])
end
