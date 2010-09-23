require 'rubygems'; require 'require_relative'
require_relative './base/cmd'

class Trepan::Command::DisassembleCommand < Trepan::Command
  ALIASES      = %w(dis)
  CATEGORY     = 'data'
  HELP         = <<-HELP
Disassemble bytecode for the current method. By default, the bytecode
for the current line is disassembled only.
    
    If the argument is 'all', the entire method is shown as bytecode.
    HELP
  NAME         = File.basename(__FILE__, '.rb')
  NEED_STACK   = true
  SHORT_HELP   = 'Show the bytecode for the current method'
  
  def run(args)
    if args[1] == "all"
      section "Bytecode for #{@current_frame.method.name}"
      msg @proc.current_method.decode
    else
      @proc.dbgr.show_bytecode
    end
  end
end

