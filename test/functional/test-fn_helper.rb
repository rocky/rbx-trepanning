#!/usr/bin/env ruby
require 'test/unit'
require 'rubygems'; require 'require_relative'
require_relative 'fn_helper'

class TestFnTestHelper < Test::Unit::TestCase

  include FnTestHelper

  def test_basic
    assert_equal(__LINE__, get_lineno, 'get_lineno()')
    assert_equal(0,
                 '-- (/tmp/trepan/tmp/gcd.rb:4)' =~ TREPAN_LOC)
    assert_equal(0, '(trepanx): exit' =~ TREPAN_PROMPT)

    output='
-- (/tmp/trepan/tmp/gcd.rb:4)
(trepanx): s
-- (/tmp/trepan/tmp/gcd.rb:18)
(trepanx): s
-- (/tmp/trepan/tmp/gcd.rb:19)
(trepanx): s
.. (/tmp/trepan/tmp/gcd.rb:0)
(trepanx): s
-> (/tmp/trepan/tmp/gcd.rb:4)
'.split(/\n/)
   expect='
-- (/tmp/trepan/tmp/gcd.rb:4)
-- (/tmp/trepan/tmp/gcd.rb:18)
-- (/tmp/trepan/tmp/gcd.rb:19)
.. (/tmp/trepan/tmp/gcd.rb:0)
-> (/tmp/trepan/tmp/gcd.rb:4)
'.split(/\n/)
  assert_equal(expect, filter_line_cmd(output))
  end
  
end






