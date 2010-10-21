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
    if 'all' == args[1]
      # FIXME: first msg is a section command.
      msg "Bytecode for #{@proc.frame.location.describe}"
      msg current_method.decode
    else
      @proc.show_bytecode
    end
  end
end

if __FILE__ == $0
  require_relative '../mock'
  dbgr, cmd = MockDebugger::setup
  def foo(cmd)
    puts "#{cmd.name}"
    cmd.run([cmd.name])
    puts '=' * 40
    puts "#{cmd.name} all"
    cmd.run([cmd.name, 'all'])
  end
  foo(cmd)
end
