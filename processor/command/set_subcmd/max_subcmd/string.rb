# -*- coding: utf-8 -*-
# Copyright (C) 2010, 2011 Rocky Bernstein <rockyb@rubyforge.net>
require 'rubygems'; require 'require_relative'
require_relative '../../base/subsubcmd'

class Trepan::SubSubcommand::SetMaxString < Trepan::SubSubcommand
  unless defined?(HELP)
    NAME         = File.basename(__FILE__, '.rb')
    # FIXME: DRY the next two lines and throw in "set" too.
    dirname      = File.basename(File.dirname(File.expand_path(__FILE__)))
    PREFIX       = %W(set #{dirname[0...-'_subcmd'.size]} #{NAME})
    DEFAULT_MIN  = 10
    DEFAULT_LENGTH  = 80

    HELP         = <<-EOH

#{PREFIX.join(' ')} [NUM]

Sometimes the string representation of an object is very long. This
setting limits how much of the string representation you want to
see. 

NUM must have a value at least #{DEFAULT_MIN}. If no value is supplied
#{DEFAULT_LENGTH} is used.

To disable any limit on the string size, use a negative number.

If the string has an embedded newline then we will assume the output
is intended to be formated as is.

Examples:
  #{PREFIX.join(' ')} #{DEFAULT_LENGTH}  # set maximum string length to 80
  #{PREFIX.join(' ')} # same as above
  #{PREFIX.join(' ')} -1  # set unlimited maximum string
  #{PREFIX.join(' ')} -10 # same as above
  #{PREFIX.join(' ')} #{DEFAULT_MIN-1} # invalid - number too small.

EOH
    MIN_ABBREV   = 'str'.size
    SHORT_HELP   = "Set maximum # chars in a string before truncation"
  end

  def run(args)
    args.shift
    args = %W(#{DEFAULT_LENGTH}) if args.empty?
    run_set_int(args.join(' '),
                "The 'set maximum string' command requires number at least #{DEFAULT_MIN}", 
                DEFAULT_MIN, nil)
  end

  alias save_command save_command_from_settings

end

if __FILE__ == $0
  # Demo it.
  require_relative '../../../mock'
  # FIXME: DRY this code.
  dbgr, set_cmd = MockDebugger::setup('set')
  max_cmd       = Trepan::SubSubcommand::SetMax.new(dbgr.processor, 
                                                    set_cmd)
  cmd_name      = Trepan::SubSubcommand::SetMaxString::PREFIX.join('')
  name          = Trepan::SubSubcommand::SetMaxString::PREFIX[0]
  subcmd        = Trepan::SubSubcommand::SetMaxString.new(set_cmd.proc, 
                                                          max_cmd,
                                                          cmd_name)
  subcmd.run([])
  subcmd.run(%W(#{name} 0))
  subcmd.run(%W(#{name} 20))
  subcmd.run(%W(#{name} 100))
  name = File.basename(__FILE__, '.rb')
  subcmd.summary_help(name)
  puts
  puts '-' * 20
  puts subcmd.save_command
end
