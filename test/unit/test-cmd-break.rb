#!/usr/bin/env ruby
require 'rubygems'; require 'require_relative'
require_relative 'cmd-helper'

class TestCommandBreak < Test::Unit::TestCase

  include UnitHelper
  def setup
    common_setup
    @cmdproc.frame_setup
    @name   = File.basename(__FILE__, '.rb').split(/-/)[2]
    @my_cmd = @cmds[@name]
    @brkpt_set_pat = /^Set breakpoint \d+: .*$/ 
  end

  def run_cmd(cmd, args) 
    cmd.proc.instance_variable_set('@cmd_argstr', args[1..-1].join(' '))
    cmd.run(args)
  end

  # require_relative '../../lib/trepanning'
  def test_basic
    assert true
    return
    # [
    #  [@name,  __LINE__.to_s],
    # ].each_with_index do |args, i|
    #   run_cmd(@my_cmd, args)
    #   assert_equal(true, @cmdproc.errmsgs.empty?, @cmdproc.errmsgs)
    #   assert_equal(0, @cmdproc.msgs[0] =~ @brkpt_set_pat, @cmdproc.msgs[0])
    #   reset_cmdproc_vars
    # end

    # pc_offset = tf.pc_offset
    # [[@name],
    #  [@name, "@#{pc_offset}"],
    #  #[@name, 'FileUtils.cp']
    # ].each_with_index do |args, i|
    #   run_cmd(@my_cmd, args)
    #   assert_equal(true, @cmdproc.errmsgs.empty?, @cmdproc.errmsgs)
    #   assert_equal(0, @cmdproc.msgs[0] =~ @brkpt_set_pat, @cmdproc.msgs[0])
    #   reset_cmdproc_vars
    # end

    common_setup
    def foo
      5 
    end
    [[@name, 'foo', (__LINE__-3).to_s]].each_with_index do |args, i|
      run_cmd(@my_cmd, args)
      assert_equal(true, @cmdproc.errmsgs.empty?,
                   @cmdproc.errmsgs)
      assert_equal(true, @cmdproc.errmsgs.empty?, @cmdproc.errmsgs)
      reset_cmdproc_vars
    end

    # [[@name, 'foo']].each_with_index do |args, i|
    #   run_cmd(@my_cmd, args)
    #   assert_equal(true, @cmdproc.errmsgs.empty?,
    #                @cmdproc.errmsgs)
    #   assert_equal(0, @cmdproc.msgs[0] =~ @brkpt_set_pat, @cmdproc.msgs[0])
    #   reset_cmdproc_vars
    # end
  end

end
