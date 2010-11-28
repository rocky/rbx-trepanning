# -*- coding: utf-8 -*-
# Copyright (C) 2010 Rocky Bernstein <rockyb@rubyforge.net>
require 'rubygems'; require 'require_relative'
require_relative '../../base/subsubcmd'

class Trepan::SubSubcommand::ShowDebugDbgr < Trepan::ShowBoolSubSubcommand
  unless defined?(HELP)
    HELP        = "Show debugging the debugger"
    NAME        = File.basename(__FILE__, '.rb')
    PREFIX      = %W(show debug #{NAME})
  end

end

if __FILE__ == $0
  # Demo it.
  require_relative '../../../mock'
  require_relative '../debug'
  cmd = MockDebugger::subsub_setup(Trepan::SubSubcommand::ShowDebug,
                                   Trepan::SubSubcommand::ShowDebugDbgr)
end
