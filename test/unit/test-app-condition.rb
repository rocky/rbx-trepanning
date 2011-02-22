#!/usr/bin/env ruby
require 'stringio'
require 'test/unit'
require 'rubygems'; require 'require_relative'
require_relative '../../app/condition'

class TestAppCondition < Test::Unit::TestCase
  include Trepan::Condition
  
  def test_basic
    assert valid_condition?('1+2')
    old_stderr = $stderr
    new_stdout = StringIO.new
    $stderr = new_stdout
    assert_equal nil, valid_condition?('1+')
    $stderr = old_stderr
  end
end
