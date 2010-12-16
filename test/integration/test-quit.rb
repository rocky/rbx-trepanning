#!/usr/bin/env ruby
require 'test/unit'
require 'rubygems'; require 'require_relative'
require_relative 'helper'

class TestQuit < Test::Unit::TestCase
  @@NAME = File.basename(__FILE__, '.rb')[5..-1]

  def test_trepanx_call
    assert_equal(true, run_debugger(@@NAME, 'null.rb'))
  end

  def test_xcode_call
    no_error = run_debugger('quit-Xdebug', 'null.rb',
                            {:xdebug => true,
                              :short_cmd => @@NAME,
                              :do_diff => false
                            })
    assert_equal(true, no_error)
    if no_error
      outfile = File.join(File.dirname(__FILE__), 'quit-Xdebug.out')
      FileUtils.rm(outfile)
    end
  end
end
