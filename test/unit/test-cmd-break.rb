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
  end
  
  def five?; 5 end
  
  def test_basic
    ["#{self.class}.test_basic:#{__LINE__}",
     'TestCommandBreak.setup', 'TestCommandBreak.five?'].each do |place|
      
      @my_cmd.run([@name, place])
      assert_equal(true, @cmdproc.errmsgs.empty?,
                   @cmdproc.errmsgs)
    end
  end

end
