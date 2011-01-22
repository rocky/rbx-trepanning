# Copyright (C) 2011 Rocky Bernstein <rockyb@rubyforge.net>
require 'rubygems'; require 'require_relative'
require_relative '../app/iseq'

class Trepan
  class CmdProcessor

    def show_bytecode(line=@frame.vm_location.line)
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

      prefixes = []
      disasm = partial.inject('') do |result, ins|
        inst = Rubinius::CompiledMethod::Instruction.new(ins, meth, ip)
        prefixes << ISeq::disasm_prefix(ip, frame.next_ip, meth)
        ip += ins.size
        result += "#{inst}\n"
      end

      # FIXME DRY with command/disassemble.rb
      if @settings[:terminal]
        require_relative '../app/llvm'
        @llvm_highlighter = CodeRay::Duo[:llvm, :term]
        # llvm_scanner = CodeRay.scanner :llvm
        # p llvm_scanner.tokenize(disasm)
        disasm = @llvm_highlighter.encode(disasm)
      end
      old_maxstring = settings[:maxstring]
      settings[:maxstring] = -1
      begin
        disasm.split("\n").each_with_index do |inst, i|
          msg "#{prefixes[i]} #{inst}"
        end
      ensure
        settings[:maxstring] = old_maxstring
      end
    end
  end
end
