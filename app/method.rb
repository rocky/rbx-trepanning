# Copyright (C) 2010 Rocky Bernstein <rockyb@rubyforge.net>
module Trepanning
  module Method

    def lines_of_method(meth)
      lines = []
      meth.lines.each_with_index do |l, i|
        lines << l if (i&1 == 1)
      end
      return lines
    end

    def find_method_with_line(meth, line)
      unless meth.kind_of?(Rubinius::CompiledMethod)
        return nil
      end
      
      lines = lines_of_method(meth)
      ## p ['++++1', meth, lines]
      return meth if lines.member?(line) 
      scope = meth.scope
      meth = scope.instance_variable_get('@script').compiled_method
      lines = lines_of_method(meth)
      ## p ['++++2', meth, lines]
      until lines.member?(line) do
        scope = scope.parent
        unless scope
          return nil
        end
        meth = scope.instance_variable_get('@script').compiled_method
        lines = lines_of_method(meth)
        ## p ['++++3', meth, lines]
      end
      return meth
    end
  end
end

if __FILE__ == $0
  include Trepanning::Method

  line = __LINE__
  def find_line(line) # :nodoc
    meth = Rubinius::VM.backtrace(0)[0].method
    p lines_of_method(meth)
    p find_method_with_line(meth, line)
  end

  meth = Rubinius::VM.backtrace(0)[0].method
  p lines_of_method(meth)
  find_line(line)
end
