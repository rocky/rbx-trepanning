# Copyright (C) 2010 Rocky Bernstein <rockyb@rubyforge.net>
require 'tempfile'
# require 'linecache'
require 'rubygems'; require 'require_relative'
require_relative '../app/frame'
require_relative '../app/util'
class Trepan
  class CmdProcessor

    include Util
    attr_reader   :current_thread

    # ThreadFrame, current frame
    attr_accessor :frame

    # frame index in a "backtrace" command
    attr_accessor :frame_index
    attr_reader   :hide_level

    # Hash[thread_id] -> FixNum, the level of the last frame to
    # show. If we called the debugger directly, then there is
    # generally a portion of a backtrace we don't want to show. We
    # don't need to store this for all threads, just those we want to
    # hide frame on. A value of 1 means to hide just the oldest
    # level. The default or showing all levels is 0.
    attr_accessor :hidelevels

    # Hash[container] -> file container. This gives us a way to map non-file
    # container objects to a file container for display.
    attr_accessor :remap_container
    
    attr_accessor :stack_size

    # top frame of current thread.
    attr_accessor :top_frame       
    # attr_reader   :threads2frames  # Hash[thread_id] -> top_frame
    

    def adjust_frame(frame_num, absolute_pos)
      frame, frame_num = get_frame(frame_num, absolute_pos)
      if frame 
        @frame = @dbgr.frame(frame_num)
        @frame_index = frame_num
        ## frame_eval_remap if 'EVAL' == @frame.type
        print_location unless @settings[:traceprint]
        @line_no = @frame.line
        @frame
      else
        nil
      end
    end

    # def frame_container(frame, canonicalize=true)
    #   container = 
    #     if @remap_container.member?(frame.source_container)
    #       @remap_container[frame.source_container]
    #     elsif frame.iseq && @remap_iseq.member?(frame.iseq.sha1)
    #       @remap_iseq[frame.iseq.sha1]
    #     else
    #       frame.source_container
    #     end

    #   container[1] = canonic_file(container[1]) if canonicalize
    #   container
    # end

    # # If frame type is EVAL, set up to remap the string to a temporary file.
    # def frame_eval_remap
    #   to_str = Trepan::Frame::eval_string(@frame)
    #   return nil unless to_str.is_a?(String)

    #   # All systems go!
    #   unless @remap_iseq.member?(@frame.iseq.sha1)
    #     tempfile = Tempfile.new(['eval-', '.rb'])
    #     tempfile.open.puts(to_str)

    #     @remap_iseq[@frame.iseq.sha1] = ['file', tempfile.path]
    #     tempfile.close
    #     LineCache::cache(tempfile.path)
    #   end
    #   return true
    # end

    # Initializes the thread and frame variables: @frame, @top_frame, 
    # @frame_index, @current_thread, and @threads2frames
    def frame_setup
      @frame_index        = 0
      @frame = @top_frame = @dbgr.current_frame
      @current_thread     = @dbgr.debugee_thread
      @line_no            = @frame.line

      @threads2frames   ||= {} 
      @threads2frames[@current_thread] = @top_frame
      set_hide_level
      ## frame_eval_remap if 'EVAL' == @frame.type
    end

    # Remove access to thread and frame variables
    def frame_teardown
      @top_frame = @frame = @frame_index = @current_thread = nil 
      @threads2frames = {}
    end

    def frame_initialize
      @remap_container = {}
      @remap_iseq      = {}
      @hidelevels      = Hash.new(nil) 
      @hide_level      = 0
    end

    def get_frame(frame_num, absolute_pos)
      if absolute_pos
        frame_num += @stack_size if frame_num < 0
      else
        frame_num += @frame_index
      end

      if frame_num < 0
        errmsg('Adjusting would put us beyond the newest frame.')
        return [nil, nil]
      elsif frame_num >= @stack_size
        errmsg('Adjusting would put us beyond the oldest frame.')
        return [nil, nil]
      end

      [frame, frame_num]
    end

    def parent_frame
      frame = @dbgr.frame(@frame.number + 1)
      unless frame
        errmsg "Unable to find parent frame at level #{@frame.number+1}"
        return nil
      end
      frame
    end

    def set_hide_level
      @hide_level = 
        if !@settings[:hidelevel] || @settings[:hidelevel] < 0
          @settings[:hidelevel] = @hidelevels[@current_thread] =  
            find_main_script(@dbgr.locations) || max_stack_size
        else
          @settings[:hidelevel]
        end
      max_stack_size = @dbgr.locations.size
      @stack_size = if @hide_level >= max_stack_size  
                      max_stack_size else max_stack_size - @hide_level
                    end
    end
      
    # def get_nonsync_frame(tf)
    #   if (tf.stack_size > 10)
    #     check_frames = (0..5).map{|i| tf.prev(i).method}
    #     if check_frames == 
    #         %w(synchronize event_processor IFUNC call trace_hook IFUNC)
    #       return tf.prev(6)
    #     end
    #   end
    #   tf
    # end

    # def get_frame_from_thread(th)
    #   if th == Thread.current
    #     @threads2frames[th]
    #   else
    #     # FIXME: Check to see if we are blocked on entry to debugger.
    #     # If so, walk back frames.
    #     tf = get_nonsync_frame(th.threadframe)
    #     @threads2frames = tf
    #   end
    # end

    # # The dance we have to do to set debugger frame state to
    # #    `frame', which is in the thread with id `thread_id'. We may
    # #    need to the hide initial debugger frames.
    # def find_and_set_debugged_frame(th, position)
      
    #   thread = threading._active[thread_id]
    #   thread_name = thread.getName()
    #   if (!@settings['dbg_pydbgr'] &&
    #       thread_name == Mthread.current_thread_name())
    #     # The frame we came in on ('current_thread_name') is
    #     # the same as the one we want to switch to. In this case
    #     # we need to some debugger frames are in this stack so 
    #     # we need to remove them.
    #     newframe = Mthread.find_debugged_frame(frame)
    #     frame = newframe unless newframe
    #   end
    #   ## FIXME: else: we might be blocked on other threads which are
    #   # about to go into the debugger it not for the fact this one got there
    #   # first. Possibly in the future we want
    #   # to hide the blocks into threading of that locking code as well. 
      
    #   # Set stack to new frame
    #   @frame, @curindex = Mcmdproc.get_stack(frame, nil, self.proc)
    #   @proc.stack, @proc.curindex = self.stack, self.curindex
      
    #   # @frame_thread_name = thread_name
    # end
  end
end

if __FILE__ == $0
  # Demo it.
  require_relative 'main'   # Have to include before defining CmdProcessor!
                            # FIXME
  class Trepan::CmdProcessor
    def errmsg(msg)
      puts msg
    end
    def print_location
      puts "frame location: #{frame.file} #{frame.line}"
    end
  end

  require_relative './mock'
  dbgr, cmd = MockDebugger::setup('exit', false)
  # require_relative '../lib/trepanning'
  # Trepan.start(:set_restart => true)
  proc  = cmd.proc
  0.upto(proc.stack_size-1) { |i| proc.adjust_frame(i, true) }
  puts '*' * 10
  proc.adjust_frame(-1, true)
  proc.adjust_frame(0, true)
  puts '*' * 10
  proc.stack_size.times { proc.adjust_frame(1, false) }
  puts '*' * 10
  proc.adjust_frame(proc.stack_size-1, true)
  proc.stack_size.times { proc.adjust_frame(-1, false) }
    
end
