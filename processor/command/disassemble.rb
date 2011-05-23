# -*- coding: utf-8 -*-
# Copyright (C) 2011 Rocky Bernstein <rockyb@rubyforge.net>
require 'rubygems'; require 'require_relative'
require_relative './base/cmd'
require_relative '../../app/method'
require_relative '../../app/iseq'

class Trepan::Command::DisassembleCommand < Trepan::Command

  include Trepanning::Method

  NAME         = File.basename(__FILE__, '.rb')
  ALIASES       = %w(disas disassem) # Note we (will) have disable
  CATEGORY     = 'data'
  HELP         = <<-HELP
#{NAME} [--all | -a]
#{NAME} [method|LINE-NUM]...

Disassembles Rubinius VM instructions. By default, the bytecode for the
current line is disassembled only.

If a method name is given, disassemble just that method. 

If a line number given, then disassemble just that line number if it
has bytecode assocated with that line. Note that if a line has
discontinuous regions we will show just the first region associated
with that line.

If the argument is '--all', the entire method is shown as bytecode.

Examples:
   #{NAME}              # dissasemble VM for current line
   #{NAME} --all        # disassemble entire current method
   #{NAME} [1,2].max    # disassemble max method of Array
   #{NAME} Object.is_a? # disassemble Object.is_a?
   #{NAME} is_a?        # same as above (probably)
   #{NAME} 6            # Disassemble line 6 if there is bytecode for it
   #{NAME} 6 is_a?      # The above two commands combined into one
    HELP

  NEED_STACK   = true
  SHORT_HELP   = 'Show the bytecode for the current method'
  DEFAULT_OPTIONS = {
      :all => false,
  }

  completion %w(-a -all)

  def disassemble_method(cm)
    frame_ip = (@proc.frame.method == cm) ? @proc.frame.next_ip : nil
    lines = cm.lines
    next_line_ip = 0
    next_i = 1
    prefixes = []
    disasm = ''
    cm.decode.each do |insn|
      show_line = 
        if insn.ip >= next_line_ip
          next_line_ip = lines.at(next_i+1)
          line_no = lines.at(next_i)
          next_i += 2
          true
        else
          false
        end
          
      prefixes << Trepan::ISeq::disasm_prefix(insn.ip, frame_ip, cm)
      str = insn.to_s
      if show_line
        str += 
          if insn.instance_variable_get('@comment')
            ' '
          elsif str[-1..-1] !~/\s/
            '    '
          else
            ''
          end
        str += "# line: #{line_no}"  
      end
      disasm += "#{str}\n"
    end

    # FIXME DRY with ../disassemble.rb
    if settings[:highlight]
      begin
        require_relative '../../app/rbx-llvm'
        @llvm_highlighter ||= CodeRay::Duo[:llvm, :term]
        # llvm_scanner = CodeRay.scanner :llvm
        # p llvm_scanner.tokenize(disasm)
        disasm = @llvm_highlighter.encode(disasm)
      rescue LoadError
        errmsg 'Highlighting requested but CodeRay is not installed.'
      end
    end
      
    disasm.split("\n").each_with_index do |inst, i|
      msg ("#{prefixes[i]} #{inst}", :unlimited => true)
    end
  end

  def parse_options(options, args) # :nodoc
    parser = OptionParser.new do |opts|
      opts.on('-a', '--all', 
              'show entire method') do
        options[:all] = true
      end
    end
    parser.parse! args
    return options

  end

  # Run command. 
  def run(args)
    my_args = args[1..-1]
    options = parse_options(DEFAULT_OPTIONS.dup, my_args)
    if my_args.empty?
      if options[:all]
        section "Bytecode for #{@proc.frame.vm_location.describe}"
        disassemble_method(current_method)
      else
        @proc.show_bytecode
      end
    else
      args[1..-1].each do |arg|
        cm = @proc.parse_method(arg)
        if cm
          section "Bytecode for method #{arg}"
          disassemble_method(cm.executable)
        else
          opts = {:msg_on_error => false }
          line_num = @proc.get_an_int(arg, opts) 
          if line_num
            cm = find_method_with_line(current_method, line_num)
            if cm
              @proc.show_bytecode(line_num)
            else
              errmsg "Can't find that bytecode for line #{line_num}"
            end
          else
            errmsg "Method #{arg} not found"
          end
        end
      end
    end
  end
end

if __FILE__ == $0
  # Demo it.
  require_relative '../mock'
  dbgr, cmd = MockDebugger::setup
  def five; 5 end
  def foo(cmd)
    puts "#{cmd.name}"
    cmd.run([cmd.name])
    puts '=' * 40
    puts "#{cmd.name} --all"
    # require_relative '../../lib/trepanning'; debugger
    cmd.run([cmd.name, '--all'])
    puts '=' * 40
    cmd.run([cmd.name, '-a'])
    puts '=' * 40
    cmd.run([cmd.name, 'five'])
    ## FIXME: someday handle:
    # puts '=' * 40
    # cmd.run([cmd.name, '-a', 'five'])
    puts '=' * 40
    cmd.run([cmd.name, 'MockDebugger::setup'])
    puts '=' * 40
    cmd.run([cmd.name, __LINE__.to_s])
    require 'irb'
    cmd.run([cmd.name, 'IRB.start'])
  end
  foo(cmd)
end
