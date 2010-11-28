# -*- coding: utf-8 -*-
# Copyright (C) 2010 Rocky Bernstein <rockyb@rubyforge.net>
require 'rubygems'; require 'require_relative'
require_relative '../../base/subsubcmd'

class Trepan::Subcommand::SetAutoDis < Trepan::SetBoolSubSubcommand
  unless defined?(HELP)
    HELP = "Set to run a 'disassemble' command each time we enter the debugger"
    MIN_ABBREV = 'd'.size
    NAME       = File.basename(__FILE__, '.rb')
    PREFIX     = %W(set auto #{NAME})
    SHORT_HELP = "Set running a 'disassemble' command each time we enter the debugger"
  end

  def run(args)
    super
    if @proc.settings[:autodis]
      @proc.cmdloop_prehooks.insert_if_new(10, *@proc.autodis_hook)
    else
      @proc.cmdloop_prehooks.delete_by_name('autodis')
    end
  end

end

if __FILE__ == $0
  # Demo it.
  require_relative '../../../mock'
  require_relative '../auto'
  cmd = MockDebugger::subsub_setup(Trepan::SubSubcommand::SetAuto,
                                   Trepan::SubSubcommand::SetAutoDis)
  cmd.run([cmd.name, 'off'])
end
