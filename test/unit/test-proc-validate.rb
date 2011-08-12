#!/usr/bin/env ruby
require 'test/unit'
require 'rubygems'; require 'require_relative'
require_relative '../../processor'
require_relative '../../processor/validate'
require_relative '../../app/mock'
require_relative 'cmd-helper'

$errors = []
$msgs   = []

# Test Trepan::CmdProcessor Validation portion
class TestValidate < Test::Unit::TestCase

  def setup
    $errors  = []
    $msgs    = []
    @dbg   ||= MockDebugger::MockDebugger.new(:nx => true)
    @cmdproc = Trepan::CmdProcessor.new(@dbg)

    class << @cmdproc
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

  def test_get_int
    [['1', 1],  ['1E', nil], ['bad', nil], ['1+1', 2], ['-5', -5]].each do 
      |arg, expected|
      assert_equal(expected, @cmdproc.get_int_noerr(arg))
    end
  end

  def test_get_on_off
    onoff = 
    [['1', true],  ['on', true],
     ['0', false], ['off', false]].each do |arg, expected|
      assert_equal(expected, @cmdproc.get_onoff(arg))
    end
  end

  include UnitHelper
  def outer_line
    @line = __LINE__
  end

  def test_parse_position
    common_setup
    outer_line
    @dbg.instance_variable_set('@current_frame',
                               Trepan::Frame.new(self, 0,
                                                 Rubinius::VM.backtrace(0, true)[0]))
    @cmdproc.frame_setup
    file = File.basename(__FILE__)
    [
     [__FILE__, [true, file, nil, nil]],
     ['@8', [true, file, 8, :offset]],
     [@line.to_s , [true, file, @line, :line]],
     ['2' , [true, file, 2, :line]],
     ["#{__FILE__}:#{__LINE__}" , [true, file, __LINE__, :line]],
     ["#{__FILE__} #{__LINE__}" , [true, file, __LINE__, :line]]
    ].each do |pos_str, expected|
      result = @cmdproc.parse_position(pos_str)
      result[1] = File.basename(result[1])
      result[0] = !!result[0]
      assert_equal(expected, result, "parsing position #{pos_str}")
    end
  end

  def test_file_exists_proc
    load 'tmpdir.rb'
    # %W(#{__FILE__} tmpdir.rb mock.rb).each do |name|
    %W(#{__FILE__}).each do |name|
      assert_equal true, @cmdproc.file_exists_proc.call(name), "Should find #{name}"
    end
    %W(#{File.dirname(__FILE__)} tmpdir).each do |name|
      assert_equal false, !!@cmdproc.file_exists_proc.call(name), "Should not find #{name}"
    end
  end

  def test_breakpoint_position
    start_line = __LINE__
    common_setup
    outer_line
    @dbg.instance_variable_set('@current_frame',
                               Trepan::Frame.new(self, 0,
                                                 Rubinius::VM.backtrace(0, true)[0]))
    @cmdproc.frame_setup

    def munge(args)
      args[0] = args[0].class
      args
    end

    assert_equal([Rubinius::CompiledMethod, start_line, 0, 'true', false],
                 munge(@cmdproc.breakpoint_position('@0', false)))
    result = @cmdproc.breakpoint_position("outer_line:#{@line}", true)
    result[0] = result[0].name
    assert_equal([:outer_line, @line, 0, 'true', false], result)
    result = @cmdproc.breakpoint_position("#{@line} unless 1 == 2", true)
    result[0] = result[0].name
    assert_equal([:outer_line, @line, 0, '1 == 2', true], result)
  end

  def test_int_list
    assert_equal([1,2,3], @cmdproc.get_int_list(%w(1+0 3-1 3)))
    assert_equal(0, $errors.size)
    assert_equal([2,3], @cmdproc.get_int_list(%w(a 2 3)))
    assert_equal(1, $errors.size)
  end

  def test_method?
    def foo; 5 end
    
    # require_relative '../../lib/rbdbgr'
    # dbgr = Trepan.new(:set_restart => true)
    # FIXME: 'foo',
    ['Array.map', 'Trepan::CmdProcessor.new',
     'errmsg'
    ].each do |str|
      # dbgr.debugger if 'foo' == str
      assert @cmdproc.method?(str), "#{str} should be known as a method"
    end
    ['food', '.errmsg'
    ].each do |str|
      # dbgr.debugger if 'foo' == str
      assert_equal(false, !!@cmdproc.method?(str),
                   "#{str} should not be known as a method")
    end

  end

end
