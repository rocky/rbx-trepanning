require 'rubygems'; require 'require_relative'
require_relative './base/cmd'

class RBDebug::Command::Continue < RBDebug::Command
  pattern "c", "cont", "continue"
  help "+1 Continue running the target thread"
  ext_help <<-HELP
Continue execution until another breakpoint is hit.
      HELP
  
  def run(args)
    listen
  end
end

