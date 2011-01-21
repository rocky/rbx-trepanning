#!/usr/bin/env ruby
require 'test/unit'
require 'rubygems'; require 'require_relative'
require_relative '../../app/iseq'

class TestAppISeq < Test::Unit::TestCase

  def test_disasm_prefix
    meth = Rubinius::VM.backtrace(0, true)[0].method
    assert_equal(' -->', Trepan::ISeq.disasm_prefix(0, 0, meth))
    assert_equal('    ', Trepan::ISeq.disasm_prefix(0, 1, meth))
    meth.set_breakpoint(0, nil)
    assert_equal('B-->', Trepan::ISeq.disasm_prefix(0, 0, meth))
    assert_equal('B   ', Trepan::ISeq.disasm_prefix(0, 1, meth))
  end

  def test_basic

    def single_return
      cm = Rubinius::VM.backtrace(0, true)[0].method
      last = cm.lines.last
      first = 0
      0.upto((cm.lines.last+1)/2) do |i|
        first = cm.lines[i*2]
        break if -1 != first
      end
      [last, Trepan::ISeq.yield_or_return_between(cm, first, last)]
    end

    def branching(bool)
      cm = Rubinius::VM.backtrace(0, true)[0].method
      last = cm.lines.last
      first = nil
      0.upto((cm.lines.last+1)/2) do |i|
        first = cm.lines[i*2]
        break if -1 != first
      end

      if bool
        x = 5
      else
        x = 6
      end
      Trepan::ISeq.goto_between(cm, first, last)
    end

    def no_branching
      cm = Rubinius::VM.backtrace(0, true)[0].method
      last = cm.lines.last
      first = 0
      0.upto((cm.lines.last+1)/2) do |i|
        first = cm.lines[i*2]
        break if -1 != first
      end
      Trepan::ISeq.goto_between(cm, first, last)
    end

    last, return_ips = single_return
    assert_equal([last-1], return_ips)
    assert_equal(-2, no_branching)
    assert_equal(2, branching(true).size)
  end

end
