#!/usr/bin/env ruby
require 'test/unit'
require 'rubygems'; require 'require_relative'
require_relative '../../app/brkptmgr'
require_relative '../../app/breakpoint'

class TestLibAppBrkptMgr < Test::Unit::TestCase

  def setup
    @meth = Rubinius::CompiledMethod.of_sender
    @brkpts = BreakpointMgr.new
    @offset = 0
  end

  def test_basic
    assert_equal(0, @brkpts.size)
    b1 = @brkpts.add("<start>", @meth, @offset, 0, 1)
    assert_equal(b1, @brkpts.find(@meth, @offset))
    assert_equal(1, @brkpts.size)
    # require 'trepanning'
    # dbgr = Trepan.new(:set_restart => true); dbgr.start
    assert_equal(b1, @brkpts.delete(b1.id))
    assert_equal(0, @brkpts.size)

    # Try adding via << rather than .add
    b2 = @brkpts << Trepan::Breakpoint.new(@meth, 5, nil, :temp => true)

    assert_equal(nil, @brkpts.find(@meth, 6))
    @brkpts.reset
    assert_equal(0, @brkpts.size)
  end

  def test_multiple_brkpt_per_offset
    b1 = @brkpts.add("b1", @meth, @offset, 5, 2)
    b2 = @brkpts.add("b2", @meth, @offset, 5, 2)
    assert_equal(2, @brkpts.size)
    assert_equal(1, @brkpts.set.size, 
                 'Two breakpoints but only one @meth/offset')
    @brkpts.delete_by_brkpt(b1)
    assert_equal(1, @brkpts.size, 
                 'One breakpoint after 2nd breakpoint deleted')
    assert_equal(1, @brkpts.set.size, 
                 'Two breakpoints, but only one @meth/offset')
    @brkpts.delete_by_brkpt(b2)
    assert_equal(0, @brkpts.size, 
                 'Both breakpoints deleted')
    assert_equal(0, @brkpts.set.size, 
                 'Second breakpoint delete should delete @meth/offset')
  end

end
