# -*- coding: utf-8 -*-
# Copyright (C) 2010 Rocky Bernstein <rockyb@rubyforge.net>
require 'rubygems'; require 'require_relative'
require_relative '../../base/subsubcmd'

class Trepan::Subcommand::SetAutoIrb < Trepan::SetBoolSubSubcommand
  unless defined?(HELP)
    HELP = "Set to automatically go into irb each time we enter the debugger"
    MIN_ABBREV = 'ir'.size
    NAME       = File.basename(__FILE__, '.rb')
    PREFIX     = %w(set auto irb)
  end

  def run(args)
    super
    if @proc.settings[:autoirb]
      @proc.cmdloop_prehooks.insert_if_new(-1, *@proc.autoirb_hook)
    else
      @proc.cmdloop_prehooks.delete_by_name('autoirb')
    end
  end

end

if __FILE__ == $0
  # Demo it.
  require_relative '../../../mock'
  require_relative '../auto'

  cmd = MockDebugger::subsub_setup(Trepan::SubSubcommand::SetAuto,
                                   Trepan::SubSubcommand::SetAutoIrb)
  cmd.run([cmd.name, 'off'])
  cmd.run([cmd.name, 'on'])
end
