require 'rubygems'; require 'require_relative'
require_relative './base/cmd'
require_relative '../../app/iseq'

class Trepan::Command::DisassembleCommand < Trepan::Command
  NAME         = File.basename(__FILE__, '.rb')
  ALIASES      = %w(dis)
  CATEGORY     = 'data'
  HELP         = <<-HELP
#{NAME} [all]

Disassembles Rubinius VM instructins. By default, the bytecode for the
current line is disassembled only.

If the argument is 'all', the entire method is shown as bytecode.

    HELP

  NEED_STACK   = true
  SHORT_HELP   = 'Show the bytecode for the current method'

  def disassemble_method(meth)
    meth.decode.each do |insn|
      prefix = Trepanning::ISeq::disasm_prefix(insn.ip, 
                                               @proc.frame.ip,
                                               @proc.frame.method)
      msg "#{prefix} #{insn}"
    end
  end

  def run(args)
    if 1 == args.size
      @proc.show_bytecode
    elsif 'all' == args[1]
      # FIXME: first msg is a section command.
      msg "Bytecode for #{@proc.frame.location.describe}"
      disassemble_method(current_method)
    else
      # str = "method(#{args[1].inspect}.to_sym)"
      # puts str
      # meth = @proc.debug_eval_no_errmsg(str)
      # if meth
      #   # FIXME: first msg is a section command.
      #   msg "Bytecode for method #{args[1]}"
      #   disassemble_method(meth)
      # else
      #   errmsg "Method #{args[1]} not found"
      # end
      errmsg "The only argument we can handle right now is 'all'"
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
