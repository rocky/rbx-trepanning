class Trepan
  class CmdProcessor

    def show_bytecode(line=@frame.location.line)
      meth = @frame.method
      start = meth.first_ip_on_line(line)
      fin = meth.first_ip_on_line(line+1)

      if fin == -1
        fin = meth.iseq.size
      end

      # FIXME: Add section in addtion to "msg"
      msg "Bytecode between #{start} and #{fin-1} for line #{line}"

      iseq_decoder = Rubinius::InstructionDecoder.new(meth.iseq)
      partial = iseq_decoder.decode_between(start, fin)

      ip = start

      partial.each do |ins|
        op = ins.shift

        ins.each_index do |i|
          case op.args[i]
          when :literal
            ins[i] = meth.literals[ins[i]].inspect
          when :local
            if meth.local_names
              ins[i] = meth.local_names[ins[i]]
            end
          end
        end

        # FIXME: was section
        msg " %4d: #{op.opcode} #{ins.join(', ')}" % ip

        ip += (ins.size + 1)
      end
    end
  end
end
  
