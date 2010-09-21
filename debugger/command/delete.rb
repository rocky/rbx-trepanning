require 'rubygems'; require 'require_relative'
require_relative './base/cmd'

class RBDebug::Command::DeleteBreakpont < RBDebug::Command
  pattern "d", "delete"
  help "Delete a breakpoint"
  ext_help "Specify the breakpoint by number, use 'info break' to see the numbers"

  def run(args)
    if !args or args.empty?
      error "Please specify which breakpoint by number"
      return
    end
    
    begin
      i = Integer(args.strip)
    rescue ArgumentError
      error "'#{args}' is not a number"
      return
    end
    
    @debugger.delete_breakpoint(i)
  end
end

