#!/usr/bin/env ruby
require 'test/unit'
require 'rubygems'; require 'require_relative'
require_relative 'helper'

class TestQuit < Test::Unit::TestCase
  @@NAME = File.basename(__FILE__, '.rb')[5..-1]

  def test_it
    assert_equal(true, run_debugger(@@NAME, 'null.rb'))
  end
end
