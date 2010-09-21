require 'rubygems'; require 'require_relative'
require_relative './next'

class RBDebug::Command::Step < RBDebug::Command::Next

  pattern "s", "step"
  help "Step into next method call or to next line"
  ext_help <<-HELP
Behaves like next, but if there is a method call on the current line,
execption is stopped in the called method.
      HELP

  def run(args)
    max = step_over_by(1)
    
    listen(true)
    
    # We remove the max position breakpoint no matter what
    max.remove! if max
    
  end
end

