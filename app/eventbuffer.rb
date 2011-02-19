#   Copyright (C) 2011 Rocky Bernstein <rockyb@rubyforge.net>
module Trace

  class EventBuffer
    EventStruct = Struct.new(:event, :arg, :frame) unless defined?(EventStruct)
    attr_reader   :buf
    attr_accessor :marks    # User position mark into buffer. If buffer is limited,
    attr_reader   :maxsize  # Maximum size of buffer or nil if unlimited.
    attr_reader   :size     # size of buffer 
    # then marks will drop out as they disappear from the buffer
    def initialize(maxsize=nil)
      @maxsize = maxsize
      reset
    end
    
    def reset
      @buf   = []
      @marks = []
      @pos   = -1
      @size  = 0 
    end
    
    # Add a new event dropping off old events if that was declared
    # marks are also dropped if buffer has a limit.
    def append(event, frame, arg)
      item = EventStruct.new(event, arg, frame)
      @pos = self.succ_pos
      @marks.shift if @marks[0] == @pos
      @buf[@pos] = item
      @size     += 1 unless @maxsize && @size == @maxsize
    end

    # Add mark for the current event buffer position.
    def add_mark
      @marks << @pos
    end

    # Like add mark, but do only if the last marked position has
    # changed
    def add_mark_nodup
      @marks << @pos unless @marks[-1] == @pos
    end
    
    def each(from=nil, to=nil)
      from = self.succ_pos unless from
      to   = @pos unless to
      if from <= to
        from.upto(to).each do |pos|
          yield @buf[pos]
        end
      else
        from.upto(@size-1).each do |pos|
          yield @buf[pos]
        end
        0.upto(@pos).each do |pos|
          yield @buf[pos]
        end
      end
    end
    
    def each_with_index(from=nil, to=nil)
      from = succ_pos unless from
      to   = @pos     unless to
      if from <= to
        from.upto(to).each do |pos|
          yield [@buf[pos], pos]
        end
      else
        from.upto(@size-1).each do |pos|
          yield [@buf[pos], pos]
        end
        0.upto(@pos).each do |pos|
          yield [@buf[pos], pos]
        end
      end
    end
    
    def format_entry(item, long_format=true)
      # require 'rbdbgr'; Debugger.debug
      mess = "#{item.event} #{item.frame}"
      # if long_format && item.iseq
      #   mess += "\n\t" + "VM offset #{item.pc_offset} of #{item.iseq.name}"
      # end
      mess
    end

    # Return the next event buffer position taking into account
    # that we may have a fixed-sized buffer ring.
    def succ_pos(inc=1)
      pos = @pos + inc 
      @maxsize ? pos % @maxsize : pos 
    end
    
    # Return the next event buffer position taking into account
    # that we may have a fixed-sized buffer ring.
    def pred_pos(dec=1)
      pos = @pos - dec
      @maxsize ? pos % @maxsize : pos 
    end
    
    # Return the adjusted zeroth position in @buf.
    def zero_pos
      if !@maxsize || @buf.size < @maxsize
        0
      else 
        self.succ_pos
      end
    end
    
  end # EventBuffer
end # Trace 

if __FILE__ == $0
  def event_processor(event, frame, arg=nil)
    begin 
      @eventbuf.append(event, frame, arg)
    rescue
      p $!
    end
  end
  def dump_all
    puts '-' * 40
    @eventbuf.each do |e| 
      puts @eventbuf.format_entry(e) if e
    end
  end

  require 'rubygems'; require 'set_trace'
  @eventbuf = Trace::EventBuffer.new(5)
  p @eventbuf.zero_pos
  dump_all

  # trace_filter = Trace::Filter.new
  # trace_func   = method(:event_processor).to_proc
  # trace_filter << trace_func
  # trace_filter.set_trace_func(trace_func)
  # z=5
  # z.times do |i|
  #   x = i
  #   y = x+2
  # end
  # trace_filter.set_trace_func(nil)
  # p @eventbuf.buf[@eventbuf.zero_pos]
  # dump_all
  @eventbuf.reset
  dump_all
end
