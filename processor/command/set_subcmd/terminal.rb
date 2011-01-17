# -*- coding: utf-8 -*-
# Copyright (C) 2010 Rocky Bernstein <rockyb@rubyforge.net>
require 'rubygems'; require 'require_relative'
require_relative '../base/subcmd'

class Trepan::Subcommand::SetTerminal < Trepan::SetBoolSubcommand
  unless defined?(HELP)
    HELP       = 'Set whether we use terminal highlighting'
    IN_LIST    = true
    MIN_ABBREV = 'ba'.size
    NAME       = File.basename(__FILE__, '.rb')
    PREFIX     = %W(set #{NAME})
  end

  def run(args)
    super
    @proc.settings[:terminal] = :term if @proc.settings[:terminal]
  end

end

if __FILE__ == $0
  # Demo it.
  $0 = __FILE__ + 'notagain' # So we don't run this again
  require_relative '../../mock'
  cmd = MockDebugger::sub_setup(Trepan::Subcommand::SetTerminal, false)
  cmd.run(cmd.prefix + ['off'])
  cmd.run(cmd.prefix + ['ofn'])
  cmd.run(cmd.prefix)
  puts cmd.save_command
end
