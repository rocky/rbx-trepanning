require 'rubygems'; require 'require_relative'
require_relative './base/cmd'

class RBDebug::Command::Next < RBDebug::Command
  pattern "n", "next"
  help "Move to the next line or conditional branch"
  ext_help <<-HELP
Attempt to continue execution and stop at the next line. If there is
a conditional branch between the current position and the next line,
execution is stopped within the conditional branch instead.

The optional argument is a number which specifies how many lines to
attempt to skip past before stopping execution.

If the current line is the last in a method, execution is stopped
at the current position of the caller.
      HELP

  def run(args)
    if !args or args.empty?
      step = 1
    else
      step = args.to_i
    end
    
    if step <= 0
      error "Invalid step count - #{step}"
      return
    end
    
    step_over_by(step)
    @debugger.listen
  end
  
  def step_over_by(step)
    f = current_frame
    
    ip = -1
    
    exec = f.method
    possible_line = f.line + step
    fin_ip = exec.first_ip_on_line possible_line
    
    if fin_ip == -1
      return step_to_parent
    end
    
    set_breakpoints_between(exec, f.ip, fin_ip)
  end
  
  def step_to_parent
    f = @debugger.frame(current_frame.number + 1)
    unless f
      info "Unable to find frame to step to next"
      return
    end
    
    exec = f.method
    ip = f.ip
    
    bp = RBDebug::BreakPoint.for_ip(exec, ip)
    bp.for_step!
    bp.activate
    
    return bp
  end
  
  def set_breakpoints_between(exec, start_ip, fin_ip)
    ips = goto_between(exec, start_ip, fin_ip)
    if ips.kind_of? Fixnum
      ip = ips
    else
      one, two = ips
      bp1 = RBDebug::BreakPoint.for_ip(exec, one)
      bp2 = RBDebug::BreakPoint.for_ip(exec, two)
      
      bp1.paired_with(bp2)
      bp2.paired_with(bp1)
      
      bp1.for_step!
      bp2.for_step!
      
      bp1.activate
      bp2.activate
      
      return bp1
    end
    
    if ip == -1
      error "No place to step to"
      return nil
    end
    
    bp = RBDebug::BreakPoint.for_ip(exec, ip)
    bp.for_step!
    bp.activate
    
    return bp
  end
  
  def next_interesting(exec, ip)
    pop = Rubinius::InstructionSet.opcodes_map[:pop]
    
    if exec.iseq[ip] == pop
      return ip + 1
    end
    
    return ip
  end
  
  def goto_between(exec, start, fin)
    goto = Rubinius::InstructionSet.opcodes_map[:goto]
    git  = Rubinius::InstructionSet.opcodes_map[:goto_if_true]
    gif  = Rubinius::InstructionSet.opcodes_map[:goto_if_false]
    
    iseq = exec.iseq
    
    i = start
    while i < fin
      op = iseq[i]
      case op
      when goto
        return next_interesting(exec, iseq[i + 1]) # goto target
      when git, gif
        return [next_interesting(exec, iseq[i + 1]),
                next_interesting(exec, i + 2)] # target and next ip
      else
        op = Rubinius::InstructionSet[op]
        i += (op.arg_count + 1)
      end
    end
    
    return next_interesting(exec, fin)
  end
  
end
