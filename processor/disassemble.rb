require 'rubygems'; require 'require_relative'
require_relative '../app/iseq'

class Trepan
  class CmdProcessor

    def show_bytecode(line=@frame.location.line)
      meth = @frame.method
      start = meth.first_ip_on_line(line)
      fin = meth.first_ip_on_line(line+1)

      if fin == -1
        fin = meth.iseq.size
      end

      # FIXME: Add section instead of "msg"
      msg "Bytecode between #{start} and #{fin-1} for line #{line}"

      iseq_decoder = Rubinius::InstructionDecoder.new(meth.iseq)
      partial = iseq_decoder.decode_between(start, fin)

      ip = start

      partial.each do |ins|
        inst = Rubinius::CompiledMethod::Instruction.new(ins, meth, ip)
        prefix = Trepanning::ISeq::disasm_prefix(ip, frame.ip, meth)
        msg "#{prefix} #{inst}"
        ip += ins.size
      end
    end
  end
end
  
