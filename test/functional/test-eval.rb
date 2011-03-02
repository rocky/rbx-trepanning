#!/usr/bin/env ruby
require 'test/unit'
require 'rubygems'; require 'require_relative'
require_relative 'fn_helper'

class TestEval < Test::Unit::TestCase

  include FnTestHelper

  def test_eval_questionmark

    # See that eval? strips 'if'
    cmds = %w(eval? continue)
    d = strarray_setup(cmds)
    d.start
    if 3 > 5
      assert false
    end
    d.stop
    out = ['-- ', 'if 3 > 5', 'eval: 3 > 5', '$d0 = false']
    compare_output(out, d, cmds)
    
    # See that eval? strips 'if' and 'then'
    cmds = %w(eval? continue)
    d = strarray_setup(cmds)
    d.start
    if 3 > 5 then
      assert false
    end
    d.stop
    out = ['-- ', 'if 3 > 5 then', 'eval: 3 > 5', '$d0 = false']
    compare_output(out, d, cmds)
    
    # See that eval? strips 'unless'
    cmds = %w(eval? continue)
    d = strarray_setup(cmds)
    d.start
    unless 3 < 5
      assert false
    end
    d.stop
    out = ['-- ', 'unless 3 < 5', 'eval: 3 < 5', '$d0 = true']
    compare_output(out, d, cmds)
    
    # See that eval? strips 'unless' and 'then
    cmds = %w(eval? continue)
    d = strarray_setup(cmds)
    d.start
    unless 3 < 5 then
      assert false
    end
    d.stop
    out = ['-- ', 'unless 3 < 5 then', 'eval: 3 < 5', '$d0 = true']
    compare_output(out, d, cmds)
    
    # See that eval? strips 'while'
    cmds = %w(eval? continue)
    d = strarray_setup(cmds)
    d.start
    while nil
      assert false
    end
    d.stop
    out = ['-- ', 'while nil', 'eval: nil', '$d0 = nil']
    compare_output(out, d, cmds)
    
    # See that eval? strips 'while' and 'do'
    cmds = %w(eval? continue)
    d = strarray_setup(cmds)
    d.start
    while nil do
      assert false
    end
    d.stop
    out = ['-- ', 'while nil do', 'eval: nil', '$d0 = nil']
    compare_output(out, d, cmds)
    
    # See that eval? strips 'until' and 'do'
    cmds = %w(eval? continue)
    d = strarray_setup(cmds)
    d.start
    until true do
      assert false
    end
    d.stop
    out = ['-- ', 'until true do', 'eval: true', '$d0 = true']
    compare_output(out, d, cmds)

    # See that eval? strips 'until'
    cmds = %w(eval? continue)
    d = strarray_setup(cmds)
    d.start
    until true
      assert false
    end
    d.stop
    out = ['-- ', 'until true', 'eval: true', '$d0 = true']
    compare_output(out, d, cmds)

    # See that eval? strips 'return'
    def five
      return 5
    end
    cmds = %w(step eval? continue)
    d = strarray_setup(cmds)
    d.start
    five
    d.stop
    out = ['-- ', 'five', '-> ', 'return 5', 'eval: 5', '$d0 = 5']
    compare_output(out, d, cmds)
  end
    
end


