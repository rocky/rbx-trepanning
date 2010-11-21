#!/usr/bin/env ruby
require 'test/unit'
require 'rubygems'; require 'require_relative'
require_relative 'fn_helper'

def discontinuous(obj)
  if klass = obj.class and klass.kind_of?(Fixnum)
    return true
  end
  return nil
end

class TestNextBug < Test::Unit::TestCase

  include FnTestHelper

  # Sometimes a line may have a disconnected set of IP. For example
  # Rubinius::VariableScope#method_visibility which has these
  # offset/lines
  #
  # ... 0, 126, 22, 127, 29, 128, 43, 130, 48, 126, 50, ...
  #        ^^^                                 ^^^
  #
  # Make sure when can "next" when we are stopped at the 2nd part of
  # line 126 (offset 50). 
  # 
  def test_next_on_line_with_discontinuous_ips
    lines = method(:discontinuous).executable.lines
    unless lines.at(3) == lines.at(7) 
      puts("Skipping #{__FILE__} test because code generated is not " +
           "what we need to test here. Please fix.")
    end
    cmds = %w(step next continue)
    d = strarray_setup(cmds)
    d.start
    discontinuous(5)
    d.stop
    out = ['-- ',
           'discontinuous(5)',
           '-> ',
           'if klass = obj.class and klass.kind_of?(Fixnum)',
           '-- ',
           'return nil'
          ]
    compare_output(out, d, cmds)
  end
end


