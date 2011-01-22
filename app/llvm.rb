# Copyright (C) 2011 Rocky Bernstein <rockyb@rubyforge.net>
# A CodeRay Scanner for Rubinius' LLVM.
# FIXME: add unit test.
require 'rubygems'
require 'coderay'
module CodeRay
  module Scanners
    
    class LLVM < Scanner
      
      include Streamable
      
      register_for :llvm
      file_extension 'llvm'

      def scan_tokens tokens, options
        
        state = :initial
        number_expected = true

        until eos?

          kind = nil
          match = nil
          
          case state

          when :initial

            if match = scan(/^\s*/)
              tokens << [match, :space]  unless match.empty?
            end
            state = 
              if match = scan(/^$/)
                :initial
              else
                :expect_label
              end

          when :expect_label
            state = 
              if match = scan(/\d+:/x)
                tokens << [match, :label]
                :expect_opcode
              else 
                match = scan(/^.*$/)
                tokens << [match, :error]
                :initial
            end
            
          when :expect_opcode
            state = 
              if scan(/(\s+)(\S+)/)
                tokens << [@match[1], :space]
                tokens << [@match[2], :reserved]
                :expect_operand
              else
                match = scan(/^(.*)$/)
                tokens << [match, :error]
                :initial
              end

          when :expect_operand
            if match = scan(/^[ \t]*/)
              tokens << [match, :space] if match
            end
            state = 
              if scan(/^(\d+)/)
                tokens << [@match[0], :integer]
                :expect_another_operand
              elsif scan(/^(:\S+)/)
                tokens << [@match[0], :symbol]
                :expect_another_operand
              elsif scan(/^"[^"]"/)
                tokens << [@match[0], :string]
                :expect_another_operand
              else
                :expect_opt_comment
              end
            
          when :expect_another_operand
            state = 
              if match = scan(/^,/)
                tokens << [@match[1], :operator]
                :expect_operand
              else
                :expect_opt_comment
              end
          when :expect_opt_comment
            if match = scan(/^[ \t]*/)
              tokens << [match, :space] unless match.empty?
            end
            if match = scan(/^$/)
              tokens << [match, :space]  unless match.empty?
            end
            if match = scan(/^#.*$/)
              tokens << [match, :comment] 
            else
              match = scan(/^.*$/)              
              tokens << [match, :error] unless match.empty?
            end
            state = :initial
          end
        end
        tokens
      end
    end
  end
end
if __FILE__ == $0
  require 'term/ansicolor'
  ruby_scanner = CodeRay.scanner :llvm
string='
     0000:  passed_arg                 1    # line: 679
     0002:  goto_if_true               8
     0004:  push_false                 
'  
  llvm_scanner = CodeRay.scanner :llvm
  tokens = llvm_scanner.tokenize(string)
  p tokens
  llvm_highlighter = CodeRay::Duo[:llvm, :term]
  puts llvm_highlighter.encode(string)
end
