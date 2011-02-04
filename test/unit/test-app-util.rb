#!/usr/bin/env ruby
require 'test/unit'
require 'rubygems'; require 'require_relative'
require_relative '../../app/util'

class TestAppUtil < Test::Unit::TestCase
  include Trepan::Util
  def test_safe_repr
    string = 'The time has come to talk of many things.'
    assert_equal(string, safe_repr(string, 50))
    assert_equal('The time...  things.', safe_repr(string, 17))
    assert_equal('"The tim... things."', safe_repr(string.inspect, 17))
    string = "'The time has come to talk of many things.'"
    assert_equal("'The tim... things.'", safe_repr(string, 17))
  end

  def test_find_main_script
    locs = Rubinius::VM.backtrace(0, true)
    i = find_main_script(locs)
    assert_equal(true, !!i)
    j = locs.size - i
    if j > 0
      locs = Rubinius::VM.backtrace(j, true)
      assert_equal(false, !!find_main_script(locs))
    end
  end
end
