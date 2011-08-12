# -*- coding: utf-8 -*-
# Copyright (C) 2010, 2011 Rocky Bernstein <rockyb@rubyforge.net>
require 'rubygems'; require 'require_relative'
require_relative '../command'

# undisplay display-number...
class Trepan::Command::UndisplayCommand < Trepan::Command
    
  unless defined?(HELP)
    NAME = File.basename(__FILE__, '.rb')
    HELP = <<EOH
undisplay DISPLAY_NUMBER ...
Cancel some expressions to be displayed when program stops.
Arguments are the code numbers of the expressions to stop displaying.
No argument means cancel all automatic-display expressions.
"delete display" has the same effect as this command.
Do "info display" to see current list of code numbers.
EOH

    ALIASES       = %w(und)
    CATEGORY      = 'data'
    NEED_STACK    = false
    SHORT_HELP    = 'Cancel some expressions to be displayed when program stops'
  end

  def run(args)
    
    if args.size == 1
      @proc.displays.clear
      return
    end
    opts = {}
    args[1..-1].each do |arg|
      opts[:msg_on_error] = '%s must be a display number' % arg
      i = @proc.get_an_int(arg, opts)
      if i 
        unless @proc.displays.delete_index(i)
          errmsg("no display number %d." % i)
          return
        end
      end
      return false
    end
  end
end

if __FILE__ == $0
  # demo it.
  require_relative '../mock'
  dbgr, cmd = MockDebugger::setup

  def run_cmd(cmd, args)
    cmd.run(args)
    puts '==' * 10
  end

  run_cmd(cmd, %W(#{cmd.name} z))
  run_cmd(cmd, %W(#{cmd.name} 1 10))
end
