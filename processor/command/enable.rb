# -*- coding: utf-8 -*-
# Copyright (C) 2010 Rocky Bernstein <rockyb@rubyforge.net>
require 'rubygems'; require 'require_relative'
require_relative 'disable'

# enable breakpoint command. Is like disable but the parameter
# to @proc.en_disable_breakpoint_by_number is different (set as
# ENABLE_PARM below).
class Trepan::Command::EnableCommand < Trepan::Command::DisableCommand

  # Silence already initialized constant .. warnings
  old_verbose = $VERBOSE  
  $VERBOSE    = nil
  NAME        = File.basename(__FILE__, '.rb')
  HELP        = <<-HELP
#{NAME} [display] bpnumber [bpnumber ...]
    
Enables the breakpoints given as a space separated list of breakpoint
numbers. See also "info break" to get a list.
  HELP

  ALIASES       = %w(en)
  SHORT_HELP    = 'Enable some breakpoints'
  $VERBOSE      = old_verbose 

  def initialize(proc)
    super
    @enable_parm = true # true if enable 
  end

end
        
if __FILE__ == $0
  require_relative '../mock'
  dbgr, cmd = MockDebugger::setup
  cmd.run([cmd.name])
  cmd.run([cmd.name, '1'])
  cmdproc = cmd.proc
  cmds = cmdproc.commands
  break_cmd = cmds['break']
  break_cmd.run(['break', cmdproc.frame.source_location[0].to_s])
  cmd.run([cmd.name, '1'])
end
