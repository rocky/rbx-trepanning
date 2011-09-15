# -*- coding: utf-8 -*-
# Copyright (C) 2010 Rocky Bernstein <rockyb@rubyforge.net>
require 'rubygems'; require 'require_relative'
require_relative '../../base/subsubcmd'

class Trepan::SubSubcommand::ShowAutoEval < Trepan::ShowBoolSubSubcommand
  unless defined?(HELP)
    HELP = "Show evaluation of unrecognized debugger commands"
    MIN_ABBREV   = 'ev'.size
    NAME         = File.basename(__FILE__, '.rb')
    PREFIX       = %W(show auto #{NAME})
    SHORT_HELP   = HELP
  end

end

if __FILE__ == $0
  # Demo it.
  require_relative '../../../mock'
  require_relative '../auto'
  cmd = MockDebugger::subsub_setup(Trepan::SubSubcommand::ShowAuto,
                                   Trepan::SubSubcommand::ShowAutoEval)

end
