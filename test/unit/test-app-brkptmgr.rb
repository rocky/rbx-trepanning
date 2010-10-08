#!/usr/bin/env ruby
require 'test/unit'
require 'rubygems'; require 'require_relative'
require_relative '../../app/brkptmgr'
require_relative '../../app/breakpoint'

class TestLibAppBrkptMgr < Test::Unit::TestCase
  
  def test_basic
    method = Rubinius::CompiledMethod.of_sender
    brkpts = BreakpointMgr.new
    assert_equal(0, brkpts.size)
    offset = 0
    b1 = brkpts.add("<start>", method, offset, 0, 1)
    assert_equal(b1, brkpts.find(method, offset))
    assert_equal(1, brkpts.size)
    # require 'trepanning'
    # dbgr = Trepan.new(:set_restart => true); dbgr.start
    assert_equal(b1, brkpts.delete(b1.id))
    assert_equal(0, brkpts.size)

    # Try adding via << rather than .add
    b2 = brkpts << Trepanning::BreakPoint.new(method, 5, nil, :temp => true)

    assert_equal(nil, brkpts.find(method, 6))
    brkpts.reset
    assert_equal(0, brkpts.size)
  end

  # def test_multiple_brkpt_per_offset
  #   tf = RubyVM::ThreadFrame.current
  #   iseq = tf.iseq
  #   offsets = iseq.offsetlines.keys
  #   offset  = offsets[0]
  #   brkpts = BreakpointMgr.new
  #   b1 = brkpts.add(iseq, offset)
  #   b2 = brkpts.add(iseq, offset)
  #   assert_equal(2, brkpts.size)
  #   assert_equal(1, brkpts.set.size, 
  #                'Two breakpoints but only one iseq/offset')
  #   brkpts.delete_by_brkpt(b1)
  #   assert_equal(1, brkpts.size, 
  #                'One breakpoint after 2nd breakpoint deleted')
  #   assert_equal(1, brkpts.set.size, 
  #                'Two breakpoints, but only one iseq/offset')
  #   brkpts.delete_by_brkpt(b2)
  #   assert_equal(0, brkpts.size, 
  #                'Both breakpoints deleted')
  #   assert_equal(0, brkpts.set.size, 
  #                'Second breakpoint delete should delete iseq/offset')
  # end

end
