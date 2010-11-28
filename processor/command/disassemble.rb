require 'rubygems'; require 'require_relative'
require_relative './base/cmd'
require_relative '../../app/iseq'

class Trepan::Command::DisassembleCommand < Trepan::Command
  NAME         = File.basename(__FILE__, '.rb')
  ALIASES      = %w(dis)
  CATEGORY     = 'data'
  HELP         = <<-HELP
#{NAME} [all|method]

Disassembles Rubinius VM instructions. By default, the bytecode for the
current line is disassembled only.

If a method name is given, disassemble just that method. If the
argument is 'all', the entire method is shown as bytecode.

Examples:
   #{NAME}              # dissasemble VM for current line
   #{NAME} all          # disassemble entire current method
   #{NAME} [1,2].max    # disassemble max method of Array
   #{NAME} Object.is_a? # disassemble Object.is_a?
   #{NAME} is_a?        # same as above (probably)

    HELP

  NEED_STACK   = true
  SHORT_HELP   = 'Show the bytecode for the current method'

  def disassemble_method(cm)
    frame_ip = (@proc.frame.method == cm) ? @proc.frame.ip : nil
    lines = cm.lines
    next_line_ip = 0
    next_i = 1
    cm.decode.each do |insn|
      show_line = 
        if insn.ip >= next_line_ip
          next_line_ip = lines.at(next_i+1)
          line_no = lines.at(next_i)
          next_i += 2
          true
        else
          false
        end
          
      prefix = Trepanning::ISeq::disasm_prefix(insn.ip, frame_ip, cm)
      str = "#{prefix} #{insn}"
      if show_line
        str += 
          if insn.instance_variable_get('@comment')
            ' '
          elsif str[-1..-1] !~/\s/
            '    '
          else
            ''
          end
        str += "# line: #{line_no}"  
      end
      msg str
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
      cm = @proc.parse_method(args[1])
      if cm
        # FIXME: first msg is a section command.
        msg "Bytecode for method #{args[1]}"
        disassemble_method(cm.executable)
      else
        errmsg "Method #{args[1]} not found"
      end
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
    puts '=' * 40
    p cmd.proc.frame.location.describe
    cmd.run([cmd.name, 'foo'])
    puts '=' * 40
    # require_relative '../../lib/trepanning'
    # debugger
    cmd.run([cmd.name, 'self.setup'])
  end
  foo(cmd)
end
