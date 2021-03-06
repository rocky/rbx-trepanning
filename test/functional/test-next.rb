#!/usr/bin/env ruby
require 'test/unit'
require 'rubygems'; require 'require_relative'
require_relative 'fn_helper'

class TestNext < Test::Unit::TestCase

  include FnTestHelper

  def test_next_same_level

    # See that we can next with parameter which is the same as 'next 1'
    cmds = %w(next next continue)
    d = strarray_setup(cmds)
    d.start
    x = 5
    y = 6
    d.stop
    out = ['-- ', 'x = 5', '-- ', 'y = 6', '-- ', 'd.stop']
    compare_output(out, d, cmds)
    
    # See that we can next with a computed count value
    cmds = ['step', 'next 5-3', 'continue']
    d = strarray_setup(cmds)
    d.start
    ########### t1 ###############
    x = 5
    y = 6
    z = 7
    ##############################
    d.stop
    out = ['-- ', 'x = 5', '-- ', 'y = 6', '-- ', 'd.stop']
    compare_output(out, d, cmds)
  end
    
  def test_next_between_fn
    
    # Next over functions
    cmds = ['next 2', 'continue']
    d = strarray_setup(cmds)
    d.start
    ########### t2 ###############
    def fact(x)
      return 1 if x <= 1
      return fact(x-1)
    end
    x = fact(4)
    y = 5
    ##############################
    d.stop # ({:remove => true})
    out = ['-- ', 'def fact(x)', '-- ', 'y = 5']
    compare_output(out, d, cmds)
  end
  
  def test_scoped_next
    # "Next" over a recursive function. We use a recursive function so
    # that we check that the temporary breakpoint created in the
    # implementation is specific to the frame. See Rubinius issue
    # #558.
    def fact(x)
      return 1 if x <= 1
      x = x * fact(x-1)
      return x
    end
    cmds = ['step', 'next 3', 'pr x', 'continue'] 
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
           '-- ',
           'return x',
           '24']
    compare_output(out, d, cmds)
  end

  # def test_next_in_exception
  #   cmds = %w(next! continue)
  #   d = strarray_setup(cmds)
  #   d.start
  #   ########### t2 ###############
  #   begin
  #     got_boom = false
  #     x = 4/0
  #   rescue
  #     got_boom = true
  #   end
  #   ##############################
  #   d.stop # ({:remove => true})
  #   out = ['-- ', 'begin']
  #   compare_output(out, d, cmds)
  # end
end


