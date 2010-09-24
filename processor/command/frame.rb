require 'rubygems'; require 'require_relative'
require_relative './base/cmd'

class Trepan::Command::FrameCommand < Trepan::Command
  CATEGORY     = 'stack'
  HELP         = <<-HELP
The argument must be a number corresponding to the frame numbers reported by
'bt'.

The frame specified is made the current frame.
      HELP
  NAME         = File.basename(__FILE__, '.rb')
  SHORT_HELP   = 'Make a specific frame in the call stack the current frame'
  
  def run(args)
    arg_str = args[1..-1].join(' ')
    unless m = /(\d+)/.match(arg_str)
      errmsg "Invalid frame number: #{args}"
      return
    end
    
    num = m[1].to_i
    
    if num >= @proc.dbgr.locations.size
      errmsg "Frame #{num} too big"
      return
    end
    
    @proc.dbgr.set_frame(num)
    
    msg @proc.frame.describe
    @proc.dbgr.show_code
  end
end

