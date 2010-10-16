# -*- coding: utf-8 -*-
# Copyright (C) 2010 Rocky Bernstein <rockyb@rubyforge.net>
require 'rubygems'; require 'require_relative'
require_relative 'up'

# Debugger "down" command. Is the same as the "up" command with the 
# direction (set by DIRECTION) reversed.
class Trepan::Command::DownCommand < Trepan::Command::UpCommand

  # Silence already initialized constant .. warnings
  old_verbose = $VERBOSE  
  $VERBOSE    = nil
  HELP = 
"d(own) [count]

Move the current frame down in the stack trace (to a newer frame). 0
is the most recent frame. If no count is given, move down 1.

See also 'up' and 'frame'.
"

  ALIASES       = %w(d)
  NAME          = File.basename(__FILE__, '.rb')
  SHORT_HELP    = 'Move frame in the direction of the caller of the last-selected frame'
  $VERBOSE      = old_verbose 

  def initialize(proc)
    super
    @direction = -1 # +1 for up.
  end

end

if __FILE__ == $0
  # Demo it.
  require_relative '../mock'
  dbgr, cmd = MockDebugger::setup

  # def sep ; puts '=' * 40 end
  # cmd.run [cmd.name]
  # %w(-1 0 1 -2).each do |count| 
  #   puts "#{cmd.name} #{count}"
  #   cmd.run([cmd.name, count])
  #   sep 
  # end
  # def foo(cmd, cmd.name)
  #   puts "#{cmd.name}"
  #   cmd.run([cmd.name])
  #   sep
  #   puts "#{cmd.name} -1"
  #   cmd.run([cmd.name, '-1'])
  # end
  # foo(cmd, cmd.name)
end
