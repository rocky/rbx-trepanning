# Module for working with instruction sequences.
class Trepan
  module ISeq
    OP_GOTO = Rubinius::InstructionSet.opcodes_map[:goto]
    OP_GOTO_IF_TRUE  = Rubinius::InstructionSet.opcodes_map[:goto_if_true]
    OP_GOTO_IF_FALSE = Rubinius::InstructionSet.opcodes_map[:goto_if_false]
    OP_RET           = Rubinius::InstructionSet.opcodes_map[:ret]
    OP_YIELD_STACK   = Rubinius::InstructionSet.opcodes_map[:yield_stack]

    module_function

    # Returns prefix string to indicate whether a breakpoint has been
    # set at this ip and or whether we are currently stopped at this ip.
    def disasm_prefix(ip, frame_ip, cm)
      prefix = cm.breakpoint?(ip) ? 'B' : ' ' 
      prefix += 
        if ip == frame_ip
          '-->'
        else
          '   '
        end
    end

    def goto_op?(cm, ip)
      [OP_GOTO, OP_GOTO_IF_TRUE, OP_GOTO_IF_FALSE].member?(cm.iseq[ip])
    end

    def goto_between(cm, start, fin)
      
      iseq = cm.iseq
      
      i = start
      while i < fin
        op = iseq[i]
        case op
        when OP_GOTO
          return next_interesting(cm, iseq[i + 1]) # goto target
        when OP_RET
          return -2
        when OP_GOTO_IF_TRUE, OP_GOTO_IF_FALSE
          return [next_interesting(cm, iseq[i + 1]),
                  next_interesting(cm, i + 2)] # target and next ip
        when nil
          return -1
        else
          # Rubinius is getting an error here sometimes. Need to figure
          # out what's wrong.
          begin
            op = Rubinius::InstructionSet[op]
          rescue TypeError
            return -1
          end
          i += (op.arg_count + 1)
        end
      end

      if fin == cm.lines.last
        return -1
      else
        return next_interesting(cm, fin)
      end
    end

    def next_interesting(cm, ip)
      pop = Rubinius::InstructionSet.opcodes_map[:pop]
      
      if cm.iseq[ip] == pop
        return ip + 1
      end
      
      return ip
    end
    
    def yield_or_return_between(cm, start, fin)
      iseq = cm.iseq
      ips = []
      i = start
      while i < fin
        op = iseq[i]
        if [OP_RET, OP_YIELD_STACK].member?(op)
          ips << i 
        end
        op = Rubinius::InstructionSet[op]
        i += (op.arg_count + 1)
      end
      return ips
    end

  end
end
if __FILE__ == $0
  vm_locations = Rubinius::VM.backtrace(0, true)
  call_loc = vm_locations[1]
  cm = call_loc.method
  puts cm.decode
  ips = nil
  puts '-' * 20
  0.upto((cm.lines.last+1)/2) do |i|
    ip = cm.lines[i*2]
    unless -1 == ip
      ips = Trepan::ISeq.yield_or_return_between(cm, ip, cm.lines.last) 
      puts "return: #{ips.inspect}"
      break 
    end
  end
  puts '-' * 20
  0.upto((cm.lines.last+1)/2) do |i|
    ip = cm.lines[i*2]
    unless -1 == ip
      ips = Trepan::ISeq.goto_between(cm, ip, cm.lines.last)
      puts "goto: #{ips.inspect}"
      break 
    end
  end
  puts Trepan::ISeq.disasm_prefix(ips[0], ips[0], cm)
  p Trepan::ISeq.disasm_prefix(10, ips[0], cm)
end
