#!/usr/bin/env ruby
require 'rubygems'; require 'require_relative'
require_relative 'cmd-helper'

class TestCommandFinish < Test::Unit::TestCase

  include UnitHelper
  def setup
    common_setup
    @cmdproc.frame_setup
    @name   = File.basename(__FILE__, '.rb').split(/-/)[2]
    @my_cmd = @cmds[@name]
  end
  
  def test_basic
    [
     [%W(#{@name}), 'finish', -1],
     [%W(#{@name} 2-1), 'finish', -1],
    ].each do |c, rtp, count|
      @cmdproc.instance_variable_set('@return_to_program', false)
      @my_cmd.run(c)
      assert_equal(rtp, @cmdproc.instance_variable_get('@return_to_program'))
      assert_equal(count, @cmdproc.instance_variable_get('@step_count'))
    end
  end

end
