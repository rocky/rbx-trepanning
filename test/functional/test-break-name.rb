#!/usr/bin/env ruby
require 'test/unit'
require 'rubygems'; require 'require_relative'
require_relative 'fn_helper'

def five
  5
end

class TestNameBreak < Test::Unit::TestCase

  include FnTestHelper

  def self.six=(val)
      @six = val
  end

  def five?(num) 5 == num; end

  def test_basic
    # Check that we can set breakpoints in parent, sibling and children
    # of sibling returns. We have one more 'continue' than we need
    # just in case something goes wrong.
    cmds = ['break Object#five', 'break TestNameBreak#five?',
            'break TestNameBreak.six=', 
            'continue', 'continue', 'continue', 'continue']
            
    d = strarray_setup(cmds)
    ##############################
    d.start 
    five 
    five?(5)
    TestNameBreak::six=6
    ##############################
    d.stop # ({:remove => true})
    out =  ["-- ",
            "five ",
            "Set breakpoint 1: foo.rb:55 (@3)",
            "Set breakpoint 2: foo.rb:55 (@3)",
            "Set breakpoint 3: foo.rb:55 (@3)",
            "xx ",
            "5",
            "xx ",
            "def five?(num) 5 == num; end",
            "xx ",
            "@six = val"]
    compare_output(out, d, cmds)
  end

end


