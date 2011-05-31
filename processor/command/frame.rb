require 'rubygems'; require 'require_relative'
require_relative './base/cmd'

class Trepan::Command::FrameCommand < Trepan::Command
  CATEGORY     = 'stack'
  HELP         = <<-HELP
frame [frame-number]
    
Change the current frame to frame `frame-number' if specified, or the
most-recent frame, 0, if no frame number specified.

A negative number indicates the position from the other or
least-recently-entered end.  So 'frame -1' moves to the oldest frame.
Any variable or expression that evaluates to a number can be used as a
position, however due to parsing limitations, the position expression
has to be seen as a single blank-delimited parameter. That is, the
expression '(5*3)-1' is okay while '( (5 * 3) - 1 )' isn't.

Examples:
   frame     # Set current frame at the current stopping point
   frame 0   # Same as above
   frame 5-5 # Same as above. Note: no spaces allowed in expression 5-5
   frame 1   # Move to frame 1. Same as: frame 0; up
   frame -1  # The least-recent frame

See also 'up', 'down', and  'backtrace'.
      HELP
  NAME         = File.basename(__FILE__, '.rb')
  SHORT_HELP   = 'Make a specific frame in the call stack the current frame'
  
  def complete(prefix)
    @proc.frame_complete(prefix, nil)
  end
  
  def run(args)

    if args.size == 1
      # Form is: "frame" which means "frame 0"
      position_str = '0'
    elsif args.size == 2
      # Form is: "frame position"
      position_str = args[1]
    # elsif args.size == 3
    #   # Form is: frame <position> <thread> 
    #   name_or_id = args[1]
    #   thread_str = args[2]
    #   th = @proc.get_thread_from_string(thread_str)
    #   if th
    #     @proc.frame_setup(th.threadframe)
    #     return
    #   else
    #     # FIXME: Give suitable error message was given
    #   end
    # else
    #   # Form should be: "frame thread" which means
    #   # "frame thread 0"
    #   position_str = '0'
    #   ## FIXME:
    #   ## @proc.find_and_set_debugged_frame(frame, thread_id)
    end

    stack_size = @proc.frame.stack_size
    if stack_size == 0
      errmsg('No frames recorded.')
      return false
    end
    low, high = @proc.frame_low_high(nil)
    opts={
      :msg_on_error => 
      "The '#{NAME}' command requires a frame number. Got: #{position_str}",
      :min_value => low, :max_value => high
    }
    frame_num = @proc.get_an_int(position_str, opts)
    return false unless frame_num
    
    @proc.adjust_frame(frame_num, true)
    return true
  end
end

if __FILE__ == $0
  # Demo it.
  require_relative '../mock'
  dbgr, cmd = MockDebugger::setup

  # def sep ; puts '=' * 40 end
  # %w(0 1 -2).each {|count| cmd.run([cmd.name, count]); sep }
  # def foo(cmd, cmd.name)
  #   cmd.proc.frame_setup(RubyVM::ThreadFrame::current)
  #   %w(0 -1).each {|count| cmd.run([cmd.name, count]); sep }
  # end
  # foo(cmd, cmd.name)
end
