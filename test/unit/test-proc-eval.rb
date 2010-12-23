#!/usr/bin/env ruby
require 'test/unit'
require 'rubygems'; require 'require_relative'
require_relative 'cmd-helper'
require_relative '../../processor/main' # Have to include before frame!
                                        # FIXME
require_relative '../../app/frame'
require_relative '../../processor/eval'
require_relative '../../processor/mock'

# Test Trepan::CmdProcessor Eval portion
class TestProcEval < Test::Unit::TestCase

  include UnitHelper
  def test_basic
    common_setup
    @dbgr    = Trepan.new
    @cmdproc = Trepan::CmdProcessor.new(@dbgrr)
    assert_equal('(eval "x = 1; y = 2")',

                 @cmdproc.fake_eval_filename('x = 1; y = 2'))
    assert_equal('(eval "x = 1;"...)',
                 @cmdproc.fake_eval_filename('x = 1; y = 2', 7))

    @cmdproc.instance_variable_set('@settings', {:stack_trace_on_error => true})
    # x = 1
    # vm_locations = Rubinius::VM.backtrace(0, true)
    # @dbgr.instance_variable_set('@vm_locations', vm_locations)
    # @cmdproc.instance_variable_set('@current_frame', 
    #                                Trepan::Frame.new(self, 0, vm_locations[0]))
    # @cmdproc.instance_variable_set('@settings', {:stack_trace_on_error => true})
    # assert_equal('1', @cmdproc.debug_eval('x = "#{x}"'))
    # x = 2
    # assert_equal('2', @cmdproc.debug_eval_no_errmsg('x = "#{x}"'))
    # assert_equal(nil, @cmdproc.debug_eval_no_errmsg('x+'))
  end
end
