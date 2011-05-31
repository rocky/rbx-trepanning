# Copyright (C) 2011 Rocky Bernstein <rockyb@rubyforge.net>
require 'rubygems'; require 'require_relative'
require_relative '../app/iseq'
require_relative 'virtual'

class Trepan::CmdProcessor < Trepan::VirtualCmdProcessor

  def show_bytecode(line=@frame.vm_location.line, ip=@frame.next_ip)
    meth = @frame.method
    if 0 == line 
      start, fin = Trepan::ISeq::ip_ranges_for_ip(@frame.method.lines, ip)[0]
    else
      start = meth.first_ip_on_line(line)
      unless start
        errmsg "Can't find bytecode for line #{line}"
        return
      end
      fin = meth.first_ip_on_line(line+1)
    end
    
    if !fin || fin == -1
      fin = meth.iseq.size
    end
    
    start += 1 if start == -1
    suffix = 
      if 0 == line 
        "tail code before line #{Trepan::ISeq::tail_code_line(meth, ip)}"
      else
        "line #{line}"
      end
    section "Bytecode between #{start} and #{fin-1} for line #{suffix}"
    
    iseq_decoder = Rubinius::InstructionDecoder.new(meth.iseq)
    partial = iseq_decoder.decode_between(start, fin)
    
    ip = start
    
    prefixes = []
    disasm = partial.inject('') do |result, ins|
      inst = Rubinius::CompiledMethod::Instruction.new(ins, meth, ip)
      prefixes << Trepan::ISeq::disasm_prefix(ip, frame.next_ip, meth)
      ip += ins.size
      result += "#{inst}\n"
    end
    
    # FIXME DRY with command/disassemble.rb
    if @settings[:highlight]
      require_relative '../app/rbx-llvm'
      @llvm_highlighter = CodeRay::Duo[:llvm, :term]
      # llvm_scanner = CodeRay.scanner :llvm
      # p llvm_scanner.tokenize(disasm)
      disasm = @llvm_highlighter.encode(disasm)
    end
    disasm.split("\n").each_with_index do |inst, i|
      msg "#{prefixes[i]} #{inst}", :unlimited => true
    end
  end
end
