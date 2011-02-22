#!/usr/bin/env ruby
require 'test/unit'
require 'rubygems'; require 'require_relative'
require_relative '../../app/breakpoint'

class TestAppBrkpt < Test::Unit::TestCase

  def test_basic
    method = Rubinius::CompiledMethod.of_sender
    b1 = Trepan::Breakpoint.new('<start>', method, 1, 2, 0)
    assert_equal(false, b1.temp?)
    assert_equal(0, b1.hits)
    assert_equal('B', b1.icon_char)
    assert_equal(true, b1.condition?(binding))
    assert_equal(1, b1.hits)
    b1.enabled = false
    assert_equal(false, b1.active?)
    assert_equal('b', b1.icon_char)
    assert_raises ArgumentError do 
      b1.activate
    end

    b2 = Trepan::Breakpoint.new('<start>', method, 0, 2, 0)
    b2.activate
    assert_equal(true, b2.active?)
    b2.remove!
    assert_equal(false, b2.active?)
    b3 = Trepan::Breakpoint.new('temp brkpt', method, 2, 3, 0, :temp => true)
    assert_equal('t', b3.icon_char)
  end
end
