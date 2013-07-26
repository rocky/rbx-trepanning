#!/usr/bin/env ruby
require 'test/unit'
require 'rubygems'; require 'require_relative'
require_relative 'helper'
require_relative '../../app/run'

class TestSyntax < Test::Unit::TestCase
  @@NAME = File.basename(__FILE__, '.rb')[5..-1]

  def test_trepanx_syntax_error
    opts = {:absolute => true}
    opts[:filter] = Proc.new{|got_lines, correct_lines|
      got_lines[0].gsub(/\".*rbx/, '"rbx')
      got_lines = [got_lines[0]]
    }
    rbx = Trepanning.whence_file('rbx')
    assert_equal(false, run_debugger(@@NAME, rbx, opts),
                  'This should give an error message')
  end

end
