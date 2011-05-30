# Copyright (C) 2010, 2011 Rocky Bernstein <rockyb@rubyforge.net>
require 'rubygems'; require 'require_relative'
require_relative '../app/display'
require_relative 'virtual'
class Trepan::CmdProcessor < Trepan::VirtualCmdProcessor
  attr_reader   :displays

  def display_initialize
    @displays = DisplayMgr.new
  end
  
  def run_eval_display(args={})
    for line in @displays.display(@frame) do 
      msg(line)
    end
  end
end
