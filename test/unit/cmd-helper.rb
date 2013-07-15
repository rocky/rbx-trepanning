require 'test/unit'
require 'rubygems'; require 'require_relative'
require_relative '../../processor/mock'
require_relative '../../processor/frame'

module UnitHelper

  module_function
  def common_setup
    @dbg      ||= MockDebugger::MockDebugger.new(:nx => true)
    @cmdproc  ||= Trepan::CmdProcessor.new(@dbg)
    @cmdproc.frame_initialize
    @cmdproc.dbgr  ||= @dbg
    @cmds     = @cmdproc.commands

    def @cmdproc.errmsg(message, opts={})
      @errmsgs << message
    end
    def @cmdproc.errmsgs
      @errmsgs
    end
    def @cmdproc.msg(message, opts={})
      @msgs << message
    end
    def @cmdproc.msgs
      @msgs
    end
    def @cmdproc.section(message, opts={})
      @msgs << message
    end
    reset_cmdproc_vars
  end

  def common_teardown
    @cmdproc.finalize
  end

  def reset_cmdproc_vars
    @cmdproc.instance_variable_set('@msgs', [])
    @cmdproc.instance_variable_set('@errmsgs', [])
  end

end

if __FILE__ == $0
  include UnitHelper
  common_setup
  p @cmdproc.msgs
  p @dbg
end
