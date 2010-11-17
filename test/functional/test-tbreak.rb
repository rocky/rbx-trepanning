#!/usr/bin/env ruby
require 'test/unit'
require 'rubygems'; require 'require_relative'
require_relative 'fn_helper'

class TestTBreak < Test::Unit::TestCase

  include FnTestHelper

  def foo
    a = 3
    b = 4
    c = 5
    d = 6
  end

  def test_basic
    # Check that temporary breaks are, well, temporary.
    # The last "continue" below isn't used. It to make sure we finish
    # the test even when the breakpoint isn't temporary.
    cmds = ['tbreak TestTBreak#foo', 'continue', 'continue', 'continue'] 
    d = strarray_setup(cmds)
    d.start
    ##############################
    2.times do 
      foo
    end
    ##############################
    d.stop # ({:remove => true})
    out = ['-- ',
           '2.times do ',
           'Set temporary breakpoint 1: foo.rb:55 (@3)',
           "x1 ",
           'a = 3'
          ]
    compare_output(out, d, cmds)
  end

end


