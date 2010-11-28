# Copyright (C) 2010 Rocky Bernstein <rockyb@rubyforge.net>
module Trepanning
  module Method

    ## FIXME: until the next two routines find their way back into 
    ## Rubinius::CompiledMethod...
    ##
    # Locates the instruction address (IP) of the first instruction on
    # the specified line if is in CompiledMethod cm only, or nil if no
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
    module_function :locate_line_in_cm

    ## FIXME: Try using Routine in Rubinius now.
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
      ## p [cm, lines_of_method(cm)]
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
    module_function :locate_line

    def lines_of_method(cm)
      lines = []
      cm.lines.each_with_index do |l, i|
        lines << l if (i&1 == 1)
      end
      return lines
    end
    module_function :lines_of_method

    # Return true if ip is the start of some instruction in meth.
    # FIXME: be more stringent.
    def valid_ip?(cm, ip)
      size = cm.lines.size
      ip >= 0 && ip < cm.lines[size-1]
    end
    module_function :valid_ip?

    # Returns a CompiledMethod for the specified line. We search the
    # current method +meth+ and then up the parent scope.  If we hit
    # the top and we can't find +line+ that way, then we
    # reverse the search from the top and search down. This will add
    # all siblings of ancestors of +meth+.
    def find_method_with_line(cm, line)
      unless cm.kind_of?(Rubinius::CompiledMethod)
        return nil
      end
      
      lines = lines_of_method(cm)
      ## p ['++++1', cm, lines]
      return cm if lines.member?(line) 
      scope = cm.scope
      return nil unless scope.current_script
      cm  = scope.current_script.compiled_method
      lines = lines_of_method(cm)
      ## p ['++++2', cm, lines]
      until lines.member?(line) do
        child = scope
        scope = scope.parent
        unless scope
          # child is the top-most scope. Search down from here.
          cm = child.current_script.compiled_method
          pair = locate_line(line, cm)
          ## pair = cm.locate_line(line)
          return pair ? pair[0] : nil
        end
        cm = scope.current_script.compiled_method
        lines = lines_of_method(cm)
        ## p ['++++3', cm, lines]
      end
      return cm
    end
    module_function :find_method_with_line
  end

end

module Rubinius
  class CompiledMethod < Executable
    ##
    # Returns the address (IP) of the first instruction in this
    # CompiledMethod that is on the specified line but not before the
    # given, or the address of the first instruction on the next code
    # line after the specified line if there are no instructions on
    # the requested line.  This method only looks at instructions
    # within the current CompiledMethod; see #locate_line for an
    # alternate method that also searches inside the child
    # CompiledMethods.

    #
    # @return [Fixnum] the address of the first instruction
    def first_ip_on_line_after(line, start_ip)
      i = 0
      last_i = @lines.size - 1
      while i < last_i
        ip = @lines.at(i)
        cur_line = @lines.at(i+1)
        if cur_line >= line and ip >= start_ip
          return ip
        end
        i += 2
      end
      -1
    end
  end
end


if __FILE__ == $0
  include Trepanning::Method
  require "#{File.dirname(__FILE__)}/../lib/trepanning"

  line = __LINE__
  def find_line(line) # :nodoc
    cm = Rubinius::VM.backtrace(0)[0].method
    p lines_of_method(cm)
    p find_method_with_line(cm, line)
  end

  cm = Rubinius::VM.backtrace(0)[0].method
  p lines_of_method(cm)
  find_line(line)
  p find_method_with_line(cm, line+2)
  ip = locate_line( __LINE__, cm)[1]
  puts "Line #{__LINE__} has ip #{ip}" 
  [-1, 0, 10, ip, 10000].each do |i|
    puts "IP #{i} is %svalid" % (valid_ip?(cm, i) ? '' : 'not ')
  end
end
