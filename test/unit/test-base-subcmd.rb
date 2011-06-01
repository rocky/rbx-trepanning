#!/usr/bin/env ruby
require 'test/unit'
require 'rubygems'; require 'require_relative'
# require_relative '../../app/core'
require_relative '../../processor/main'
require_relative '../../processor/command/exit'
require_relative '../../processor/command/base/subcmd'

$errors = []
class TestBaseSubCommand < Test::Unit::TestCase

  Trepan::Subcommand.const_set(:NAME, 'bogus')
  def setup
    $errors   = []
    $msgs     = []
    @dbgr     = Trepan.new
    # @core     = Trepan::Core.new(@dbgr)
    @cmdproc  = Trepan::CmdProcessor.new(@dbgr)
    @cmds     = @cmdproc.instance_variable_get('@commands')
    @exit_cmd = @cmds['exit']
    @exit_subcmd = Trepan::Subcommand.new(@exit_cmd)
    def @exit_subcmd.msg(message)
      $msgs << message
    end
    def @exit_subcmd.errmsg(message)
      $errors << message
    end
  end

  def test_base_subcommand
    assert @exit_subcmd
    assert_raises RuntimeError do 
      @exit_subcmd.run
    end
    assert_equal([], $errors)
    @exit_subcmd.run_set_int('', 'testing 1 2 3')
    assert_equal(1, $errors.size)
    assert_equal(Fixnum, @exit_subcmd.settings[:maxwidth].class)
    @cmds.each do |cmd_name, cmd_obj|
      next unless cmd_obj.is_a?(Trepan::SubcommandMgr)
      cmd_obj.subcmds.subcmds.each do |subcmd_name, subcmd_obj|
        %w(HELP NAME PREFIX).each do |attr|
          assert_equal(true, subcmd_obj.class.constants.member?(attr),
                       "Constant #{attr} should be defined in \"#{cmd_obj.name} #{subcmd_obj.class::NAME}\"")
        end
      end
      
    end
  end

  def test_show_on_off
    assert_equal('on', @exit_subcmd.show_onoff(true))
    assert_equal('off', @exit_subcmd.show_onoff(false))
    assert_equal('unset', @exit_subcmd.show_onoff(nil))
    assert_equal('??', @exit_subcmd.show_onoff(5))
  end
end
