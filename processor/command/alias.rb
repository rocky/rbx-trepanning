# Copyright (C) 2010, 2011 Rocky Bernstein <rockyb@rubyforge.net>
require 'rubygems'; require 'require_relative'
require_relative '../command'

class Trepan::Command::AliasCommand < Trepan::Command

  unless defined?(HELP)
    NAME = File.basename(__FILE__, '.rb')
    HELP = <<-HELP
#{NAME} ALIAS COMMAND

Add an alias for a COMMAND

See also 'unalias' and 'show #{NAME}'.
    HELP

    CATEGORY      = 'support'
    MAX_ARGS      = 2  # Need at most this many
    NEED_STACK    = true
    SHORT_HELP    = 'Add an alias for a debugger command'
  end
  
  # Run command. 
  def run(args)
    if args.size == 1
      @proc.commands['show'].run(%W(show #{NAME}))
    elsif args.size == 2
      @proc.commands['show'].run(%W(show #{NAME} #{args[1]}))
    else
      junk, al, command = args
      old_command = @proc.aliases[al]
      if @proc.commands.member?(command)
        @proc.aliases[al] = command
        if old_command
          msg("Alias '#{al}' for command '#{command}' replaced old " + 
              "alias for '#{old_command}'.")
        else
          msg "New alias '#{al}' for command '#{command}' created."
        end
      else
        errmsg "You must alias to a command name, and '#{command}' isn't one."
      end
    end
  end
end

if __FILE__ == $0
  # Demo it.
  require_relative '../mock'
  dbgr, cmd = MockDebugger::setup
  cmd.run %W(#{cmd.name} yy foo)
  cmd.run [cmd.name]
  cmd.run %W(cmd.name yy next)
end
