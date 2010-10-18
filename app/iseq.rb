# Module for working with instruction sequences.
module Trepanning
  module ISeq
    OP_GOTO = Rubinius::InstructionSet.opcodes_map[:goto]
    OP_GOTO_IF_TRUE  = Rubinius::InstructionSet.opcodes_map[:goto_if_true]
    OP_GOTO_IF_FALSE = Rubinius::InstructionSet.opcodes_map[:goto_if_false]
    OP_RET           = Rubinius::InstructionSet.opcodes_map[:ret]

    def goto_between(meth, start, fin)
      
      iseq = meth.iseq
      
      i = start
      while i < fin
        op = iseq[i]
        case op
        when OP_GOTO
          return next_interesting(meth, iseq[i + 1]) # goto target
        when OP_GOTO_IF_TRUE, OP_GOTO_IF_FALSE
          return [next_interesting(meth, iseq[i + 1]),
                  next_interesting(meth, i + 2)] # target and next ip
        else
          op = Rubinius::InstructionSet[op]
          i += (op.arg_count + 1)
        end
      end

      if fin == meth.lines.last
        return -1
      else
        return next_interesting(meth, fin)
      end
    end

    def next_interesting(meth, ip)
      pop = Rubinius::InstructionSet.opcodes_map[:pop]
      
      if meth.iseq[ip] == pop
        return ip + 1
      end
      
      return ip
    end
    
    def return_between(meth, start, fin)
      iseq = meth.iseq
      ips = []
      i = start
      while i < fin
        op = iseq[i]
        case op
        when OP_RET
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
  meth = call_loc.method
  puts meth.decode
  ips = return_between(meth, meth.lines.first, meth.lines.last)
  puts "return: #{ips.inspect}"
  ips = goto_between(meth, meth.lines.first, meth.lines.last)
  puts "goto: #{ips.inspect}"
end
