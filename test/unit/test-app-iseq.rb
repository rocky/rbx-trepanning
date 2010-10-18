#!/usr/bin/env ruby
require 'test/unit'
require 'rubygems'; require 'require_relative'
require_relative '../../app/iseq'

class TestAppISeq < Test::Unit::TestCase
  include Trepanning::ISeq
  def test_basic

    def single_return
      meth = Rubinius::VM.backtrace(0, true)[0].method
      first, last = [meth.lines.first, meth.lines.last]
      [last, return_between(meth, first, last)]
    end

    def branching(bool)
      meth = Rubinius::VM.backtrace(0, true)[0].method
      first, last = [meth.lines.first, meth.lines.last]
      if bool
        x = 5
      else
        x = 6
      end
      goto_between(meth, first, last)
    end

    def no_branching
      meth = Rubinius::VM.backtrace(0, true)[0].method
      first, last = [meth.lines.first, meth.lines.last]
      goto_between(meth, first, last)
    end

    last, return_ips = single_return
    assert_equal([last-1], return_ips)
    assert_equal(-1, no_branching)
    assert_equal(2, branching(true).size)
  end

end
