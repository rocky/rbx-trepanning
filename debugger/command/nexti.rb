require 'rubygems'; require 'require_relative'
require_relative './next'

class RBDebug::Command::NextInstruction < RBDebug::Command::Next
  pattern "ni", "nexti"
  help "Move to the next bytecode instruction"
  ext_help <<-HELP
Continue but stop execution at the next bytecode instruction.

Does not step into send instructions.
      HELP
  
  def run(args)
    if args and !args.empty?
      step = args.to_i
    else
      step = 1
    end
    
    exec = current_method
    insn = Rubinius::InstructionSet[exec.iseq[current_frame.ip]]
    
    next_ip = current_frame.ip + insn.width
    
    if next_ip >= exec.iseq.size
      step_to_parent
    elsif is_a_goto(exec, current_frame.ip)
      set_breakpoints_between(exec, current_frame.ip, next_ip)
    else
      line = exec.line_from_ip(next_ip)
      
      bp = RBDebug::BreakPoint.for_ip(exec, next_ip)
      bp.for_step!
      bp.activate
    end
    
    listen
  end
  
  def is_a_goto(exec, ip)
    goto = Rubinius::InstructionSet.opcodes_map[:goto]
    git  = Rubinius::InstructionSet.opcodes_map[:goto_if_true]
    gif  = Rubinius::InstructionSet.opcodes_map[:goto_if_false]
    
    i = exec.iseq[ip]
    
    case i
    when goto, git, gif
      return true
    end
    
    return false
  end
end
