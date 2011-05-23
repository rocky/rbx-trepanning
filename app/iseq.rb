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

    def ip_ranges_for_line(lines, line)
      result = []
      in_range = false
      start_ip = nil
      total = lines.size
      i = 1
      while i < total
        cur_line = lines.at(i)
        if cur_line == line
          start_ip = lines.at(i-1)
          in_range = true
        elsif cur_line > line && in_range
          result << [start_ip, lines.at(i-1)]
          start_ip = nil
          in_range = false
        end
        i += 2
      end
      if in_range && start_ip
        result << [start_ip, lines.at(total-1)]
      end
      result
    end
    
    # Return range of ips covering ip. There will be only one of these.
    # We surround this in another list to match the format of 
    # ip_ranges_for_line.
    def ip_ranges_for_ip(lines, ip)
      total = lines.size
      i = 0
      while i < total and lines.at(i) <= ip
        i += 2
      end
      [[lines.at(i-2), lines.at(i)]]
    end
  
    def next_interesting(cm, ip)
      pop = Rubinius::InstructionSet.opcodes_map[:pop]
      
      if cm.iseq[ip] == pop
        return ip + 1
      end
      
      return ip
    end

    # start is assumed to be on a tail code "synthesized" line, which
    # has line number 0. Follow opcodes until we get to a line that is
    # not 0. 
    def tail_code_line(cm, start)
      
      iseq = cm.iseq
      
      i = start
      fin = cm.lines.last
      while i < fin
        line_no = cm.line_from_ip(i)
        return line_no if line_no > 0
        op = iseq[i]
        case op
        when OP_GOTO_IF_TRUE, OP_GOTO_IF_FALSE, OP_GOTO
        when OP_GOTO
          i = iseq[i+1]
        when OP_RET
          return -2
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
      return 0
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
