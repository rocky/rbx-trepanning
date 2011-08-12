require 'rubygems'; require 'require_relative'
require_relative '../command'
require_relative '../stepping'
require_relative '../../app/breakpoint'
require_relative '../../app/iseq'

class Trepan::Command::NextInstructionCommand < Trepan::Command
  ALIASES      = %w(ni)
  CATEGORY     = 'running'
  HELP         = <<-HELP
Continue but stop execution at the next bytecode instruction.

Does not step into send instructions.

See also 'continue', 'step', and 'next' commands.
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
    insn = Rubinius::InstructionSet[exec.iseq[@proc.frame.next_ip]]
    
    next_ip = @proc.frame.next_ip + insn.width
    
    if next_ip >= exec.iseq.size
      @proc.step_to_parent
    elsif ISeq.goto_op?(exec, @proc.frame.next_ip)
      @proc.set_breakpoints_between(exec, @proc.frame.next_ip, next_ip)
    else
      line = exec.line_from_ip(next_ip)
      
      bp = Breakpoint.for_ip(exec, next_ip, :event => 'vm-insn')
      bp.scoped!(@proc.frame.scope)
      bp.activate
    end
    @proc.continue('nexti')
  end
end

if __FILE__ == $0
  require_relative '../mock'
  dbgr, cmd = MockDebugger::setup
end
