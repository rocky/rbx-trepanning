# Copyright (C) 2011 Rocky Bernstein <rockyb@rubyforge.net>
require 'rubygems'; require 'require_relative'
require_relative 'base/cmd'
class Trepan::Command::CompleteCommand < Trepan::Command

  unless defined?(HELP)
    HELP = 
"complete COMMAND-PREFIX

List the completions for the rest of the line as a command.

NOTE: For now we just handle completion of the first token.
"
    CATEGORY      = 'support'
    NAME          = File.basename(__FILE__, '.rb')
    NEED_STACK    = false
    SHORT_HELP    = 'List the completions for the rest of the line as a command'
  end

  # This method runs the command
  def run(args) # :nodoc
    if args.size == 2
      cmd_matches = @proc.commands.keys.select do |cmd|
        cmd.start_with?(args[1])
      end
      alias_matches = @proc.aliases.keys.select do |cmd|
        cmd.start_with?(args[1]) && !cmd_matches.member?(@proc.aliases[cmd])
      end
      (cmd_matches+alias_matches).sort.each do |match|
        msg match
      end
    else # FIXME: handle more complex completions
    end
  end
end

if __FILE__ == $0
  # Demo it.
  require_relative '../mock'
  dbgr, cmd = MockDebugger::setup
  %w(d b bt).each do |prefix|
    cmd.run [cmd.name, prefix]
    puts '=' * 40
  end
  cmd.run %w(#{cmd.name} fdafsasfda)
  puts '=' * 40
end
