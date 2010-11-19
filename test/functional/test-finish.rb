#!/usr/bin/env ruby
require 'test/unit'
require 'rubygems'; require 'require_relative'
require_relative 'fn_helper'

class TestFinish < Test::Unit::TestCase

  include FnTestHelper

  def test_finish_between_fn
    # "Finish" over a recursive function. We use a recursive function
    # so that we check that the temporary breakpoint created in the
    # implementation is specific to the frame. See Rubinius issue
    # #558.
    def fact(x)
      return 1 if x <= 1
      x = x * fact(x-1)
      return x
    end
    # An extra 'continue' added in case something goes wrong.
    cmds = %w(step finish) + ['pr x', 'continue', 'continue'] 
    d = strarray_setup(cmds)
    d.start
    ##############################
    x = fact(4)
    y = 5
    ##############################
    d.stop # ({:remove => true})
    out = ['-- ',
           'x = fact(4)',
           '-> ',
           'return 1 if x <= 1',
           '<- ',
           'return x',
           '24']
    compare_output(out, d, cmds)
  end
  
  def test_finish_between_fn_simple
    
    # Finish over functions
    def five; 5 end
    def something(x)
      return 1 if x <= 1
      x = 
        if five > 5
          24
        else
          22
        end
    end
    cmds = %w(step finish) + ['pr x', 'continue'] 
    d = strarray_setup(cmds)
    d.start
    ##############################
    x = something(4)
    y = 5
    ##############################
    d.stop # ({:remove => true})
    out = [
           '-- ', 
           'x = something(4)', 
           '-> ',
           'return 1 if x <= 1',
           '<- ',
           '22', '22']
    compare_output(out, d, cmds)
  end
  
end
