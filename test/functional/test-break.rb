#!/usr/bin/env ruby
require 'test/unit'
require 'rubygems'; require 'require_relative'
require_relative 'fn_helper'

class TestBreak < Test::Unit::TestCase

  include FnTestHelper

  def test_line_only_break
    # Check that we can set breakpoints in parent, sibling and children
    # of sibling returns. We have one more 'continue' than we need
    # just in case something goes wrong.
    cmds_pat = ((['break %d'] * 4) + (%w(continue) * 4)).join("\n")
    line = __LINE__
    cmds = (cmds_pat % [line, line+6, line+11, line+14]).split(/\n/)
    d = strarray_setup(cmds)
    ##############################
    def foo      # line +  4  
      a = 5      # line +  5
      b = 6      # line +  6
    end          # line +  7
    1.times do   # line +  8 
      d.start    # line +  9
      1.times do # line + 10
        x = 11   # line + 11
        foo      # line + 12
      end        # line + 13
      c = 14     # line + 14
    end
    ##############################
    d.stop # ({:remove => true})
    out = ["-- ",
           '1.times do # line + 10',
           'Set breakpoint 1: foo.rb:55 (@3)',
           'Set breakpoint 2: foo.rb:55 (@3)',
           'Set breakpoint 3: foo.rb:55 (@3)',
           'Set breakpoint 4: foo.rb:55 (@3)',
           'xx ',
           'x = 11   # line + 11',
           'xx ',
           'b = 6      # line +  6',
           'xx ',
           'c = 14     # line + 14'
          ]
    compare_output(out, d, cmds)
  end

end


