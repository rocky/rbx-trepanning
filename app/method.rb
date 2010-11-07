# Copyright (C) 2010 Rocky Bernstein <rockyb@rubyforge.net>
module Trepanning
  module Method

    ## FIXME: until the next two routines find their way back into 
    ## Rubinius::CompiledMethod...
    ##
    # Locates the instruction address (IP) of the first instruction on
    # the specified line it is in CompiledMethod cm. or nil if no
    # match for the specified line is found.
    #
    # @return [Fixnum, NilClass] returns
    #   nil if nothing is found, else the first IP for the line
    def locate_line_in_cm(line, cm=self)
      cm.lines.each_with_index do |l, i|
        next unless (i&1 == 1)
        if (l ==  line)
          # Found target line - return first IP
          return cm.lines[i-1]
        elsif l > line
          return nil
        end
      end
      return nil
    end

    ## As of Nov 6. 2010 the following method in Rubinius needs
    ## adjusting.

    ##
    # Locates the CompiledMethod and instruction address (IP) of the
    # first instruction on the specified line. This method recursively
    # examines child compiled methods until an exact match for the
    # searched line is found.  It returns both the matching
    # CompiledMethod and the IP of the first instruction on the
    # requested line, or nil if no match for the specified line is
    # found.
    #
    # @return [(Rubinius::CompiledMethod, Fixnum), NilClass] returns
    #   nil if nothing is found, else an array of size 2 containing the method
    #   the line was found in and the IP pointing there.
    def locate_line(line, cm=self)
      ip = locate_line_in_cm(line, cm)
      return cm, ip if ip

      # Didn't find line in this CM, so check if a contained
      # CM encompasses the line searched for
      cm.child_methods.each do |child|
        if res = locate_line(line, child)
          return res
        end
      end

      # No child method is a match - fail
      return nil
    end

    def lines_of_method(meth)
      lines = []
      meth.lines.each_with_index do |l, i|
        lines << l if (i&1 == 1)
      end
      return lines
    end

    # Returns a CompiledMethod for the specified line. We search the
    # current method +meth+ and then up the parent scope.  If we hit
    # the top and we can't find +line+ that way, then we
    # reverse the search from the top and search down. This will add
    # all siblings of ancestors of +meth+.
    def find_method_with_line(meth, line)
      unless meth.kind_of?(Rubinius::CompiledMethod)
        return nil
      end
      
      lines = lines_of_method(meth)
      ## p ['++++1', meth, lines]
      return meth if lines.member?(line) 
      scope = meth.scope
      meth  = scope.current_script.compiled_method
      lines = lines_of_method(meth)
      ## p ['++++2', meth, lines]
      until lines.member?(line) do
        child = scope
        scope = scope.parent
        unless scope
          # child is the top-most scope. Search down from here.
          meth = child.current_script.compiled_method
          pair = locate_line(line, meth)
          return pair ? pair[0] : nil
        end
        meth = scope.current_script.compiled_method
        lines = lines_of_method(meth)
        ## p ['++++3', meth, lines]
      end
      return meth
    end
  end
end

if __FILE__ == $0
  include Trepanning::Method
  require "#{File.dirname(__FILE__)}/../lib/trepanning"

  line = __LINE__
  def find_line(line) # :nodoc
    meth = Rubinius::VM.backtrace(0)[0].method
    p lines_of_method(meth)
    p find_method_with_line(meth, line)
  end

  meth = Rubinius::VM.backtrace(0)[0].method
  p lines_of_method(meth)
  find_line(line)
  p find_method_with_line(meth, line+2)
end
