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

      def string_parse(tokens)
        if match = scan(/^"[^"]*"/)
          string = match.dup
          while  "\\" == match[-2..-2]
            match = scan(/^.*"/)
            break unless match 
            string << match 
          end
          tokens << [string, :string]
          true
        else
          false
        end
      end

      def space_parse(tokens)
        if match = scan(/^[ \t]*/)
          tokens << [match, :space] if match
        end
      end

      def scan_tokens(tokens, options)
        
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
                opcode = @match[2]
                tokens << [opcode, :reserved]
                if %w(push_literal create_block set_literal).member?(opcode)
                  :expect_literal
                else
                  :expect_operand
                end
              else
                match = scan(/^(.*)$/)
                tokens << [match, :error]
                :initial
              end

          when :expect_literal
            space_parse(tokens)
            if match = scan(/^#<.+>/)
              tokens << [match, :content]
            elsif scan(/^(\d+)/)
              tokens << [@match[0], :integer]
            elsif scan(/^([:][^: ,\n]+)/)
              tokens << [@match[0], :symbol]
            elsif string_parse(tokens)
              # 
            elsif match = scan(/nil|true|false/)
              tokens << [match, :pre_constant]
            elsif match = scan(/\/.*\//)
              tokens << [match, :entity]
            else
              match = scan(/^.*$/)              
              tokens << [match, :error] unless match.empty?
              end
            state = :expect_opt_comment
            
          when :expect_operand
            space_parse(tokens)
            state = 
              if scan(/^(\d+)/)
                tokens << [@match[0], :integer]
                :expect_another_operand
              elsif scan(/^([:][^: ,\n]+)/)
                tokens << [@match[0], :symbol]
                :expect_another_operand
              elsif string_parse(tokens)
                :expect_another_operand
              else
                :expect_opt_comment
              end
            
          when :expect_another_operand
            state = 
              if match = scan(/^,/)
                tokens << [@match[0], :operator]
                :expect_operand
              else
                :expect_opt_comment
              end
          when :expect_opt_comment
            space_parse(tokens)
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
     0003:  push_literal               #<Rubinius::CompiledMethod gcd file=/x>
     0028:  create_block               #<Rubinius::CompiledMethod __block__ file=/y>
     0007:  send_stack                 :method_visibility, 0
     0046:  push_literal               "The GCD of %d and %d is %d"
     0000:  passed_arg                 1    # line: 679
     0002:  goto_if_true               8
     0004:  push_false                 
     0080:  push_literal               "\n     0003:  push_literal               #<Rubinius::CompiledMethod gcd file=/x>\n     0028:  create_block               #<Rubinius::CompiledMethod __block__ file=/y>\n     0007:  send_stack                 :method_visibility, 0\n     0046:  push_literal               \"    # line: 147
'  
  llvm_scanner = CodeRay.scanner :llvm
  tokens = llvm_scanner.tokenize(string)
  p tokens
  llvm_highlighter = CodeRay::Duo[:llvm, :term]
  puts llvm_highlighter.encode(string)
end
