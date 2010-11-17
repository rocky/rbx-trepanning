#!/usr/bin/env ruby
require 'test/unit'
require 'rubygems'; require 'require_relative'
require_relative '../../app/method'

class TestAppMethod < Test::Unit::TestCase

  def test_find_method_with_line
    method = Rubinius::VM.backtrace(0, true)[0].method
    line = __LINE__
    ##############################
    def foo                        # line +  2
      a = 5                        # line +  3
      b = 6                        # line +  4
    end                            # line +  5
    1.times do                     # line +  6 
      1.times do                   # line +  7
        x = 11                     # line +  8
        foo                        # line +  9
      end                          # line + 10
      c = 14                       # line + 11
    end                            # line + 12
    ################################################
    meths = []                     # line + 14
    expect = Array.new(22, true)  # line + 15
    [5, 10, 12, 13, 18].each do |i|
      expect[i] = false             # line + 17
    end                            # line + 18
    (2..21).each do |l|            # line + 19
      meth = Trepanning::Method.find_method_with_line(method, line+l)
      meths << meth                # line + 21
      assert_equal(expect[l], !!meth, "Mismatched line #{line+l}")
    end
    pairs = [[1,2], [0,4], [5,9], [6,7], [14,15], [20,21]]
    pairs.each do |pair|
      assert_equal(meths[pair[0]].inspect, meths[pair[1]].inspect, 
                   "Method compare")
    end
  end
  def test_valid_ip?
    meth = Rubinius::VM.backtrace(0, true)[0].method
    ip = Trepanning::Method.locate_line( __LINE__, meth)[1]
    assert_equal(true, ip.kind_of?(Fixnum), 
                 "locate line of #{__LINE__} should have gotten an IP;" +
                 " got: #{ip.inspect}")
    [[-1, false],
     [ 0, true], 
     [ip, true], 
     [100000, false]].each do |ip, expect|
      assert_equal expect, Trepanning::Method.valid_ip?(meth, ip)
    end
  end

end
