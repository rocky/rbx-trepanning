require 'rubygems'; require 'require_relative'
require_relative './base/cmd'

class RBDebug::Command::SetTempBreakPoint < RBDebug::Command
  pattern "tb", "tbreak", "tbrk"
  help "Set a temporary breakpoint"
  ext_help "Same as break, but the breakpoint is deleted when it is hit"
  
  def run(args)
    super args, true
  end
end

