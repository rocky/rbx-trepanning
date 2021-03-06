#!/usr/bin/env ruby
require 'test/unit'
require 'rubygems'; require 'require_relative'
require_relative '../../processor'
require_relative '../../processor/frame'
require_relative '../../processor/list'
require_relative '../../processor/mock'

# Test Trepan::CmdProcessor List portion
class TestProcList < Test::Unit::TestCase

  def setup
    $errors = []
    $msgs   = []
    @dbgr = MockDebugger::MockDebugger.new
    @proc = Trepan::CmdProcessor.new(@dbgr)
    @proc.frame_index = 0
    @proc.frame_initialize
    class << @proc
      def msg(msg)
        $msgs << msg
      end
      def errmsg(msg)
        $errors << msg
      end
      def print_location
        # $msgs << "#{@frame.source_container} #{@frame.source_location[0]}"
        $msgs << "#{@frame.source_container} "
        # puts $msgs
      end
    end
  end

  def test_basic
    @proc.frame_setup

    def foo; 5 end
    def check(cmdp, arg, last=10)
      r =  cmdp.parse_list_cmd('.', last)
      assert r[1]
      assert r[2]
      assert r[3]
    end
    check(@proc, '-')
    check(@proc, 'foo')
    check(@proc, '@0')
    check(@proc, "#{__LINE__}")
    check(@proc, "#{__FILE__}   @0")
    check(@proc, "#{__FILE__}:#{__LINE__}")
    check(@proc, "#{__FILE__} #{__LINE__}")
    check(@proc, "#{__FILE__} #{__LINE__}", -10)
    check(@proc, "@proc.errmsg")
    check(@proc, "@proc.errmsg:@0")
  end
end
