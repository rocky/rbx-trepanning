#!/usr/bin/env ruby
require 'rubygems'; require 'require_relative'
require_relative 'cmd-helper'
require_relative '../../processor/command/list'

class TestCommandParseListCmd < Test::Unit::TestCase
  include UnitHelper
  def setup
    common_setup
    @cmd = @cmds['list']
  end
  def test_parse_list_cmd
    @dbg.instance_variable_set('@current_frame',
                               Trepan::Frame.new(self, 0,
                                                 Rubinius::VM.backtrace(0, true)[0]))
    @cmdproc.frame_setup
    short_file = File.basename(__FILE__)
    listsize = 10
    line = __LINE__ - 14
    load 'tmpdir.rb'
    [['', [short_file, line, line+listsize-1]],
     ["#{__FILE__}:10", [short_file, 5, 14]],
     ["#{__FILE__} 10", [short_file, 5, 14]],
     ['tmpdir.rb', ['tmpdir.rb', 1, listsize]],
     ['tmpdir.rb 10', ['tmpdir.rb', 5, 5+listsize-1]],
     ['Columnize.columnize 15', ['columnize.rb', 10, 10+listsize -1]],
     ['Columnize.columnize 30 3', ['columnize.rb', 30, 32]],
     ['Columnize.columnize 40 50', ['columnize.rb', 40, 50]],
    ].each do |arg_str, expect|
      got = @cmd.parse_list_cmd(arg_str, listsize, listsize/2)[1..-1]
      got[0] = File.basename(got[0])
      assert_equal expect, got, arg_str
    end
  end

end
