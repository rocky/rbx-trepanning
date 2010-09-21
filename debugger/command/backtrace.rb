require 'rubygems'; require 'require_relative'
require_relative './base/cmd'

class RBDebug::Command::Backtrace < RBDebug::Command
  pattern "bt", "backtrace"
  help "Show the current call stack"
  ext_help <<-HELP
Show the call stack as a simple list.

Passing "-v" will also show the values of all locals variables
in each frame.
      HELP
  
  def run(args)
    verbose = (args =~ /-v/)
    
    if m = /(\d+)/.match(args)
      count = m[1].to_i
    else
      count = nil
    end
    
    info "Backtrace:"
    
    @debugger.each_frame(current_frame) do |frame|
      return if count and frame.number >= count
      
      info "%4d %s" % [frame.number, frame.describe]
      
      if verbose
        frame.local_variables.each do |local|
          info "       #{local} = #{frame.run(local.to_s).inspect}"
        end
      end
    end
  end
end

