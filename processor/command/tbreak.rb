require 'rubygems'; require 'require_relative'
require_relative './base/cmd'
require_relative 'break'

class Trepan::Command::SetTempBreakpointCommand < 
    Trepan::Command::BreakCommand
  ALIASES      = %w(tb tbrk)
  CATEGORY     = 'breakpoints'
  NAME         = File.basename(__FILE__, '.rb')
  HELP         = <<-HELP
Same as break, but the breakpoint is deleted when it is hit.
      HELP
  SHORT_HELP   = 'Set a temporary breakpoint'
  
  def run(args)
    super args, true
  end
end

