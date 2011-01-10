#!/usr/bin/env ruby
require 'test/unit'
require 'rubygems'; require 'require_relative'
require_relative 'helper'

class TestInlineCall < Test::Unit::TestCase
  @@NAME = File.basename(__FILE__, '.rb')[5..-1]
  def test_inline_call
    opts = {
      :short_cmd => @@NAME, :do_diff => true,
      :standalone => true
    }
    opts[:filter] = Proc.new{|got_lines, correct_lines|
      got_lines[0] = "-- (inline-call.rb:11 @12)\n"
    }

    no_error = run_debugger(@@NAME, @@NAME + '.rb', opts)
    assert_equal(true, no_error)
  end
end
