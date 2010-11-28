# Module for working with instruction sequences.
module Trepanning
  module ISeq
    OP_GOTO = Rubinius::InstructionSet.opcodes_map[:goto]
    OP_GOTO_IF_TRUE  = Rubinius::InstructionSet.opcodes_map[:goto_if_true]
    OP_GOTO_IF_FALSE = Rubinius::InstructionSet.opcodes_map[:goto_if_false]
    OP_RET           = Rubinius::InstructionSet.opcodes_map[:ret]
    OP_YIELD_STACK   = Rubinius::InstructionSet.opcodes_map[:yield_stack]

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
    module_function :disasm_prefix

    def goto_op?(cm, ip)
      [OP_GOTO, OP_GOTO_IF_TRUE, OP_GOTO_IF_FALSE].member?(cm.iseq[ip])
    end
    module_function :goto_op?

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
        else
          op = Rubinius::InstructionSet[op]
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
  include Trepanning::ISeq
  locations = Rubinius::VM.backtrace(0, true)
  call_loc = locations[1]
  cm = call_loc.method
  puts cm.decode
  ips = yield_or_return_between(cm, cm.lines.first, cm.lines.last)
  puts "return: #{ips.inspect}"
  ips = goto_between(cm, cm.lines.first, cm.lines.last)
  puts "goto: #{ips.inspect}"
  puts Trepanning::ISeq::disasm_prefix(ips[0], ips[0], cm)
  p Trepanning::ISeq::disasm_prefix(10, ips[0], cm)
end
