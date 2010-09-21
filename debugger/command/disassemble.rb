require 'rubygems'; require 'require_relative'
require_relative './base/cmd'

class RBDebug::Command::Disassemble < RBDebug::Command
  pattern "dis", "disassemble"
  help "+2 Show the bytecode for the current method"
  ext_help <<-HELP
Disassemble bytecode for the current method. By default, the bytecode
for the current line is disassembled only.
    
    If the argument is 'all', the entire method is shown as bytecode.
    HELP
  
  def run(args)
    if args and args.strip == "all"
      section "Bytecode for #{@current_frame.method.name}"
      puts current_method.decode
    else
      @debugger.show_bytecode
    end
  end
end

