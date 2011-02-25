#!/usr/bin/env ruby
require 'test/unit'
require 'rubygems'; require 'require_relative'
require_relative '../../app/validate'

class TestAppValidate < Test::Unit::TestCase
  include Trepan::Validate
  def test_line_or_ip
    [
     ['@2',   [2, nil]],
     ['oink', [nil, nil]],
     ['1'   , [nil, 1]],
     ['12',   [nil, 12]],
     ['-12',  [nil, -12]]].each do |arg, expect|
      assert_equal(line_or_ip(arg), expect)
    end
  end
end
