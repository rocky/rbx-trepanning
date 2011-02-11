#!/usr/bin/env ruby
require 'test/unit'
require 'rubygems'; require 'require_relative'
require_relative 'helper'

class TestQuit < Test::Unit::TestCase
  @@NAME = File.basename(__FILE__, '.rb')[5..-1]

  # FIXME: causes rubinius to hang. Use
  #   rbx -Xagent.start -S rake
  # to see backtrace
  # def test_trepanx_set_confirm_off
  #   opts = {}
  #   opts[:filter] = Proc.new{|got_lines, correct_lines|
  #     got_lines[0] = "-> (null.rb:1 @0)\n"
  #   }
  #   assert_equal(true, run_debugger('quit2', 'null.rb', opts))
  # end

  def test_trepanx_call
    opts = {}
    opts[:filter] = Proc.new{|got_lines, correct_lines|
      got_lines[0] = "-> (null.rb:1 @0)\n"
    }
    assert_equal(true, run_debugger(@@NAME, 'null.rb', opts))
  end

  def test_xcode_call
    startup_file = File.join(ENV['HOME'], '.rbxrc')
    lines = File.open(startup_file).readlines.grep(/Trepan\.start/)
    if lines && lines.any?{|line| line.grep(/:Xdebug/)}
      no_error = run_debugger('quit-Xdebug', 'null.rb',
                              {:xdebug => true,
                                :short_cmd => @@NAME,
                                :do_diff => false
                              })
      assert_equal(true, no_error)
      if no_error
        outfile = File.join(File.dirname(__FILE__), 'quit-Xdebug.out')
        FileUtils.rm(outfile)
      end
    else
      puts "Trepan.start(:skip_loader=>:Xdebug) is not in ~.rbxrc. Skipping."
      assert true
    end
  end
end
