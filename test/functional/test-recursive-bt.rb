#!/usr/bin/env ruby
require 'test/unit'
require 'rubygems'; require 'require_relative'
require_relative 'fn_helper'

class TestRecursiveBt < Test::Unit::TestCase

  include FnTestHelper

  def test_recursive_backtrace

    cmds = [
            'set basename on',
            'next',
            'bt 1',
            'step',
            'step',
            'bt 2',
            'step',
            'step',
            'bt 3',
            'step',
            'step',
            'step',
            'bt 5',
            'step',
            'step',
            'step',
            'bt 7',
            'continue'
            ]
    d = strarray_setup(cmds)
    d.start
    ##############################
    def factorial(n)
      if n > 0
        return n * factorial(n-1)
      else
        return 1
      end
    end
    z = factorial(5)
    ##############################
    d.stop
    out = 
      ["-- ",
       "def factorial(n)",
       "basename is on.",
       "-- ",
       "z = factorial(5)",
       "--> #0 TestRecursiveBt#test_recursive_backtrace at test-recursive-bt.rb:42",
       "(More stack frames follow...)",
       "-> ",
       "if n > 0",
       "-- ",
       "return n * factorial(n-1)",
       "--> #0 TestRecursiveBt#factorial(n) at test-recursive-bt.rb:37",
       "    #1 TestRecursiveBt#test_recursive_backtrace at test-recursive-bt.rb:42",
       "(More stack frames follow...)",
       "-> ",
       "if n > 0",
       "-- ",
       "return n * factorial(n-1)",
       "--> #0 TestRecursiveBt#factorial(n) at test-recursive-bt.rb:37",
       "    #1 TestRecursiveBt#factorial(n) at test-recursive-bt.rb:37",
       "    #2 TestRecursiveBt#test_recursive_backtrace at test-recursive-bt.rb:42",
       "(More stack frames follow...)",
       "-> ",
       "if n > 0",
       "-- ",
       "return n * factorial(n-1)",
       "-> ",
       "if n > 0",
       "--> #0 TestRecursiveBt#factorial(n) at test-recursive-bt.rb:36",
       "    #1 TestRecursiveBt#factorial(n) at test-recursive-bt.rb:37",
       "... above line repeated 2 times",
       "    #4 TestRecursiveBt#test_recursive_backtrace at test-recursive-bt.rb:42",
       "(More stack frames follow...)",
       "-- ",
       "return n * factorial(n-1)",
       "-> ",
       "if n > 0",
       "-- ",
       "return n * factorial(n-1)",
       "--> #0 TestRecursiveBt#factorial(n) at test-recursive-bt.rb:37",
       "    #1 TestRecursiveBt#factorial(n) at test-recursive-bt.rb:37",
       "... above line repeated 3 times",
       "    #5 TestRecursiveBt#test_recursive_backtrace at test-recursive-bt.rb:42",
       "    #6 Test::Unit::TestCase(TestRecursiveBt)#run(result) at testcase.rb:78",
       "(More stack frames follow...)"]
    compare_output(out, d, cmds)

  end
end
