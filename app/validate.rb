# Copyright (C) 2010 Rocky Bernstein <rockyb@rubyforge.net>

class Trepan
  module Validate
    def line_or_ip(arg_str)
      arg=arg_str.dup
      is_ip = 
        if '@' == arg[0..0]
          arg[0] = ''
          true
        else
          false
        end
      line_or_ip = Integer(arg) rescue nil
      if is_ip 
        return line_or_ip, nil
      else
        return nil, line_or_ip
      end
    end
    module_function :line_or_ip
  end
end

if __FILE__ == $0
  include Trepan::Validate
  %w(@1 oink 1 12 -12).each do |arg|
    puts "line_or_ip(#{arg})=#{line_or_ip(arg).inspect}"
  end
end
