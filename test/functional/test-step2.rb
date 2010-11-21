#!/usr/bin/env ruby
require 'test/unit'
require 'rubygems'; require 'require_relative'
require_relative 'fn_helper'

class TestStep2 < Test::Unit::TestCase

  include FnTestHelper

  def test_step_out_of_fn

    # See that handle stepping out of a function properly.
    cmds = ['step', 'step', 'continue']
    d = strarray_setup(cmds)

    def echo(x)
      return x
    end

    d.start
    ########### t1 ###############
    x = echo("hi")
    y = 3
    ##############################
    d.stop
    out = ['-- ', 
           'x = echo("hi")', 
           '-> ', 
           'return x', 
           '-- ', 
           'x = echo("hi")']
    compare_output(out, d, cmds)
  end

end
