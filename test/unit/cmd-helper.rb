require 'rubygems'; require 'require_relative'
# require_relative '../../app/core'
require_relative '../../app/mock'
require_relative '../../processor/main' # Have to include before frame!
                                        # FIXME
# require_relative '../../processor/frame'


module UnitHelper

  def common_setup
    @dbg      = Trepan.new(:nx => true)
    @cmdproc  = Trepan::CmdProcessor.new(@dbg)
    @cmdproc.frame = Rubinius::VM.backtrace(0)[1]
    @cmdproc.dbgr  = @dbg
    @cmds     = @cmdproc.commands

    def @cmdproc.msg(message)
      @msgs << message
    end
    def @cmdproc.errmsg(message)
      @errmsgs << message
    end
    def @cmdproc.errmsgs
      @errmsgs
    end
    def @cmdproc.msgs
      @msgs
    end
    reset_cmdproc_vars
  end
  module_function :common_setup
  
  def reset_cmdproc_vars
    @cmdproc.instance_variable_set('@msgs', [])
    @cmdproc.instance_variable_set('@errmsgs', [])
  end
  module_function :reset_cmdproc_vars
end

if __FILE__ == $0
  include UnitHelper
  common_setup
  p @cmdproc.msgs
  p @dbg
end
