#!/usr/bin/env ruby
require 'test/unit'
require 'rubygems'; require 'require_relative'
require_relative 'fn_helper'

class TestBreak < Test::Unit::TestCase

  include FnTestHelper

  def test_list_frame_change
    # Check that list update the frame position
    # of sibling returns. We have one more 'continue' than we need
    # just in case something goes wrong.
    cmds_pat = [
                'set max list 2',
                'list', 
                "continue %d", 
                'list',
                'up',
                'list', 
                'continue'].join("\n")
    line = __LINE__
    cmds = (cmds_pat % (line+5)).split(/\n/)
    d = strarray_setup(cmds)
    ##############################
    def foo      # line +  4  
      a = 5      # line +  5
      b = 6      # line +  6
    end          # line +  7
    d.start      # line +  8
    foo
    ##############################
    d.stop # ({:remove => true})
    out = [
           "-- ",
           "foo",
           "max list is 2.",
           " 31  ->\t    foo",
           " 32    \t    ##############################",
           "Set temporary breakpoint 1: foo.rb:55 (@3)",
           "x1 ",
           "a = 5      # line +  5",
           " 27  ->\t      a = 5      # line +  5",
           " 28    \t      b = 6      # line +  6",
           "   ",
           "foo",
           " 31  ->\t    foo",
           " 32    \t    ##############################"
          ]
    compare_output(out, d, cmds)
  end

end


