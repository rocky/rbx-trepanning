require 'rubygems'; require 'require_relative'
require_relative './base/cmd'

class RBDebug::Command::SetFrame < RBDebug::Command
  pattern "f", "frame"
  help "Make a specific frame in the call stack the current frame"
  ext_help <<-HELP
The argument must be a number corrisponding to the frame numbers reported by
'bt'.

The frame specified is made the current frame.
      HELP
  
  def run(args)
    unless m = /(\d+)/.match(args)
      error "Invalid frame number: #{args}"
      return
    end
    
    num = m[1].to_i
    
    if num >= @debugger.locations.size
      error "Frame #{num} too big"
      return
    end
    
    @debugger.set_frame(num)
    
    info current_frame.describe
    @debugger.show_code
  end
end

