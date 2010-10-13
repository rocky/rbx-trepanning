#!/usr/bin/env ruby
require 'test/unit'
require 'rubygems'; require 'require_relative'
require_relative '../../processor/main' # Have to include before frame!
                                        # FIXME
require_relative '../../processor/frame'
require_relative '../../processor/mock'

$errors = []
$msgs   = []

# Test Trepan::CmdProcessor Frame portion
class TestCmdProcessorFrame < Test::Unit::TestCase

  def setup
    $errors = []
    $msgs   = []
    @dbgr = MockDebugger::MockDebugger.new
    @proc = Trepan::CmdProcessor.new(@dbgr)
    @proc.frame_index = 0
    @proc.frame_initialize
    class << @proc
      def errmsg(msg)
        $errors << msg
      end
      def print_location
        # $msgs << "#{@frame.source_container} #{@frame.source_location[0]}"
        $msgs << File.basename(@frame.file)
        # puts $msgs
      end
    end
  end

  # See that we have can load up commands
  def test_basic
    @proc.frame_setup

    # Test absolute positioning. Should all be okay
    0.upto(@proc.stack_size-1) do |i| 
      @proc.adjust_frame(i, true) 
      assert_equal(0, $errors.size)
      assert_equal(i+1, $msgs.size)
    end

    # Test absolute before the beginning fo the stack
    frame_index = @proc.frame_index
    @proc.adjust_frame(-1, true)
    assert_equal(0, $errors.size)
    assert_equal(frame_index, @proc.frame_index)
    @proc.adjust_frame(-@proc.stack_size-1, true)
    assert_equal(1, $errors.size, $errors)
    assert_equal(frame_index, @proc.frame_index)

    ## FIXME: look over and reinstate this code...
    # setup
    # @proc.top_frame  = @proc.frame = @dbgr.locations[0]
    # @proc.adjust_frame(0, true)

    # @dbgr.locations.size-1.times do 
    #   frame_index = @proc.frame_index
    #   @proc.adjust_frame(1, false) 
    #   assert_equal(0, $errors.size)
    #   assert_not_equal(frame_index, @proc.frame_index,
    #                    '@proc.frame_index should have moved')
    # end

    # FIXME: bug in threadframe top_frame.stack_size? 
    # # Adjust relative beyond the end
    # @proc.adjust_frame(1, false) 
    # assert_equal(1, $errors.size)

    # Should have stayed at the end
    # proc.adjust_frame(proc.top_frame.stack_size-1, true)
    # proc.top_frame.stack_size.times { proc.adjust_frame(-1, false) }

  end


end
