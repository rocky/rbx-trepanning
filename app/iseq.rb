# Frame code from reference debugger.
module Trepanning
  module ISeq
    def goto_between(meth, start, fin)
      goto = Rubinius::InstructionSet.opcodes_map[:goto]
      git  = Rubinius::InstructionSet.opcodes_map[:goto_if_true]
      gif  = Rubinius::InstructionSet.opcodes_map[:goto_if_false]
      
      iseq = meth.iseq
      
      i = start
      while i < fin
        op = iseq[i]
        case op
        when goto
          return next_interesting(meth, iseq[i + 1]) # goto target
        when git, gif
          return [next_interesting(meth, iseq[i + 1]),
                  next_interesting(meth, i + 2)] # target and next ip
        else
          op = Rubinius::InstructionSet[op]
          i += (op.arg_count + 1)
        end
      end
      
      return next_interesting(meth, fin)
    end

    def is_a_goto(meth, ip)
      goto = Rubinius::InstructionSet.opcodes_map[:goto]
      git  = Rubinius::InstructionSet.opcodes_map[:goto_if_true]
      gif  = Rubinius::InstructionSet.opcodes_map[:goto_if_false]
      
      i = meth.iseq[ip]
      
      case i
      when goto, git, gif
        case i
        when goto, git, gif
          return true
        end
        
        return false
      end
    end

    def return_between(meth, start, fin)
      ret = Rubinius::InstructionSet.opcodes_map[:ret]
      iseq = meth.iseq
      ips = []
      i = start
      while i < fin
        op = iseq[i]
        case op
        when ret
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
  puts "call_loc: #{is_a_goto(meth, call_loc.ip).inspect}"
  puts meth.decode
  ips = return_between(meth, meth.lines.first, meth.lines.last)
  puts "meth.lines.return_between: #{ips.inspect}"
end
