#!/usr/bin/env ruby
require 'rubygems'; require 'require_relative'
require 'test/unit'
require_relative '../../app/display'
require_relative '../../app/frame'

class TestLibAppBrkptMgr < Test::Unit::TestCase

  def test_basic
    mgr = DisplayMgr.new
#    frame = Trepan::Frame.new(self, 0, Rubinius::VM.backtrace(0)[1])
    assert_equal(0, mgr.size)
#    disp = mgr.add(frame, '3 > 1')
#    assert_equal(1, mgr.max)
#    assert_equal(true, disp.enabled?)
    
#    mgr.enable_disable(disp.number, false)
#    assert_equal(false, disp.enabled?)
#    mgr.enable_disable(disp.number, true)
#    assert_equal(true, disp.enabled?)
  end
end
