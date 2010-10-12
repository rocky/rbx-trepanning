require 'rubygems'; require 'require_relative'
require_relative './next'

class Trepan::Command::NextInstructionCommand < Trepan::Command::NextCommand
  ALIASES      = %w(ni)
  CATEGORY     = 'running'
  HELP         = <<-HELP
Continue but stop execution at the next bytecode instruction.

Does not step into send instructions.
      HELP
  NAME         = File.basename(__FILE__, '.rb')
  NEED_STACK   = true
  SHORT_HELP   = 'Move to the next bytecode instruction'
  
  def run(args)
    if args.size == 1
      step = 1
    else
      step_str = args[1]
      opts = {
        :msg_on_error => 
        "The 'next' command argument must eval to an integer. Got: %s" % 
        step_str,
        :min_value => 1
      }
      step = @proc.get_an_int(step_str, opts)
      return unless step
    end
    
    exec = current_method
    insn = Rubinius::InstructionSet[exec.iseq[@proc.frame.ip]]
    
    next_ip = @proc.frame.ip + insn.width
    
    if next_ip >= exec.iseq.size
      step_to_parent
    elsif is_a_goto(exec, @proc.frame.ip)
      set_breakpoints_between(exec, @proc.frame.ip, next_ip)
    else
      line = exec.line_from_ip(next_ip)
      
      bp = Trepanning::Breakpoint.for_ip(exec, next_ip, :event => 'vm-insn')
      bp.for_step!
      bp.activate
    end
    @proc.return_to_program
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
