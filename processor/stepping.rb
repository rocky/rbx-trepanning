require 'rubygems'; require 'require_relative'
class Trepan
  class CmdProcessor
    def step_over_by(step)
      f = @frame
      
      ip = -1
      
      exec = f.method
      possible_line = f.line + step
      fin_ip = exec.first_ip_on_line possible_line
      
      if fin_ip == -1
        return step_to_parent
      end
      
      set_breakpoints_between(exec, f.ip, fin_ip)
    end
    
    def step_to_return
      f = @frame
      unless f
        msg 'Unable to find frame to finish'
        return
      end
      
      exec = f.method
      ip = -1
      fin_ip = exec.lines.last
      
      set_breakpoints_between(exec, f.ip, fin_ip)
      bp = Trepanning::Breakpoint.for_ip(exec, ip, {:event => 'return'})
      bp.for_step!
      bp.activate
      
      return bp
    end
    
    def step_to_parent
      f = @dbgr.frame(@frame.number + 1)
      unless f
        msg 'Unable to find frame to step to next'
        return
      end
      
      exec = f.method
      ip = f.ip
      
      bp = Trepanning::Breakpoint.for_ip(exec, ip, {:event => 'return'})
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
        bp1 = Trepanning::Breakpoint.for_ip(exec, one, {:event => 'line'})
        bp2 = Trepanning::Breakpoint.for_ip(exec, two, {:event => 'line'})
        
        bp1.paired_with(bp2)
        bp2.paired_with(bp1)
        
        bp1.for_step!
        bp2.for_step!
        
        bp1.activate
        bp2.activate
        
        return bp1
      end
      
      if ip == -1
        errmsg "No place to step to"
        return nil
      end
      
      bp = Trepanning::Breakpoint.for_ip(exec, ip, {:event => 'line'})
      bp.for_step!
      bp.activate
      
      return bp
    end
    
    def set_breakpoints_on_return_between(exec, start_ip, fin_ip)
      ips = return_between(exec, start_ip, fin_ip)
      bp1 = nil
      0.upto(ips.size-1) do |i| 
        bp1 = Trepanning::Breakpoint.for_ip(exec, i, {:event => 'return'})
        # FIXME handle pairing
        # bp2 = Trepanning::Breakpoint.for_ip(exec, two, {:event => 'return'})
        # bp1.paired_with(bp2)
        # bp2.paired_with(bp1)
        
        bp1.for_step!
        # bp2.for_step!
        
        # bp1.activate
        # bp2.activate
        return bp1
      end
      
      if nil == bp1
        errmsg 'Return not found'
        return nil
      end
      
      return bp1
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

    def return_between(exec, start, fin)
      ret = Rubinius::InstructionSet.opcodes_map[:ret]
      
      iseq = exec.iseq
      
      ips = []
      i = start
      while i < fin
        op = iseq[i]
        case op
        when ret
          ips << i 
        else
          op = Rubinius::InstructionSet[op]
          i += (op.arg_count + 1)
        end
      end
      
      return ips
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
end
