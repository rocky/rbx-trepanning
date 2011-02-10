#!/usr/bin/env ruby
# Unit test for interface.user

require 'test/unit'
require 'rubygems'; require 'require_relative'
require_relative '../../interface/user'

# Tests Trepan::UserInterface
class TestInterfaceUser < Test::Unit::TestCase

  # Test UserInterface.confirm()
  def test_confirm
    
    user_intf = Trepan::UserInterface.new(nil, nil, {:history_save => false})
    def user_intf.readline(prompt)
      $response_answer
    end

    ['y', 'Y', 'Yes', '  YES  '].each do |s|
      $response_answer = s
      ans = user_intf.confirm('Testing', true)
      assert_equal(true, ans)
    end
    
    ['n', 'N', 'No', '  NO  '].each do |s|
      $response_answer = s
      ans = user_intf.confirm('Testing', true)
      assert_equal(false, ans)
    end

    def user_intf.readline(prompt)
      raise EOFError
    end

    [true, false].each do |tf|
      assert_equal(tf, user_intf.confirm('default testing', tf))
    end

    # Ok, we'll throw in one test of EOFError
    assert_raises EOFError do 
      user_intf.readline('')
    end

  end
  # FIXME: more thorough testing of other routines in user.
end
