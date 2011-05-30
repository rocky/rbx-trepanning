# Copyright (C) 2010, 2011 Rocky Bernstein <rockyb@rubyforge.net>
require 'rubygems'; require 'require_relative'
require_relative 'virtual'
require_relative '../app/brkptmgr'
class Trepan::CmdProcessor < Trepan::VirtualCmdProcessor

  attr_reader   :brkpts          # BreakpointManager. 
  
  attr_reader   :brkpt           # Breakpoint. If we are stopped at a
                                 # breakpoint this is the one we
                                 # found.  (There may be other
                                 # breakpoints that would have caused a stop
                                 # as well; this is just one of them).
                                 # If no breakpoint stop this is nil.

  def breakpoint_initialize
    @brkpts = Trepan::BreakpointMgr.new
    @brkpt  = nil
  end
  
  def breakpoint_finalize
    @brkpts.finalize
  end
  
  def breakpoint?
    @brkpt = @dbgr.breakpoint
    return !!@brkpt && %w(tbrkpt brkpt).member?(@brkpt.event)
  end
  
  def breakpoint_find(bpnum, show_errmsg = true)
    if 0 == @brkpts.size 
      errmsg('No breakpoints set.') if show_errmsg
      return nil
    elsif bpnum > brkpts.size || bpnum < 1
      errmsg('Breakpoint number %d is out of range 1..%d' %
             [bpnum, brkpts.size]) if show_errmsg
      return nil
    end
    bp = @brkpts[bpnum]
    unless bp
      errmsg "Unknown breakpoint '#{bpnum}'" if show_errmsg
      return nil
    end
    bp
  end
  
  def set_breakpoint_method(meth, line=nil, ip=nil,
                            opts={:event => 'brkpt', :negate=>false,
                              :temp => false})
    cm =  
      if meth.kind_of?(Method) || meth.kind_of?(UnboundMethod)
        meth.executable 
      else
        meth
      end
    
    unless cm.kind_of?(Rubinius::CompiledMethod)
      errmsg "Unsupported method type: #{cm.class}"
      return nil
    end
    
    if line && line > 0
      ip = cm.first_ip_on_line(line, -2)
      
      unless ip
        errmsg "Unknown line '#{line}' in method '#{cm.name}'"
        return nil
      end
    elsif !ip
      line = cm.first_line
      ip = 0
    end
    
    # def lines without code will have value -1.
    ip = 0 if -1 == ip
    
    bp = @brkpts.add(meth.name, cm, ip, line, @brkpts.max+1, opts)
    bp.activate
    msg("Set %sbreakpoint #{bp.id}: #{meth.name}() at #{bp.location}" % 
        (opts[:temp] ? 'temporary ' : ''))
    return bp
  end
  
  # MRI 1.9.2 code
  # def breakpoint_find(bpnum, show_errmsg = true)
  #   if 0 == @brkpts.size 
  #     errmsg('No breakpoints set.') if show_errmsg
  #     return nil
  #   elsif bpnum > @brkpts.max || bpnum < 1
  #     errmsg('Breakpoint number %d is out of range 1..%d' %
  #            [bpnum, @brkpts.max]) if show_errmsg
  #     return nil
  #   end
  #   bp = @brkpts[bpnum]
  #   if bp
  #     return bp
  #   else
  #     errmsg('Breakpoint number %d previously deleted.' %
  #            bpnum) if show_errmsg
  #     return nil
  #   end
  # end
  
  # # Does whatever needs to be done to set a breakpoint
  # def breakpoint_line(line_number, iseq, temp=false)
  #   # FIXME: handle breakpoint conditions.
  #   iseq = iseq.child_iseqs.detect do |iseq|
  #     iseq.lineoffsets.keys.member?(line_number) 
  #   end
  #   offset = 
  #     if iseq 
  #       # FIXME
  #       iseq.line2offsets(line_number)[1] || iseq.line2offsets(line_number)[0]
  #     else
  #       nil
  #     end
  #   unless offset
  #     place = "in #{iseq.source_container.join(' ')} " if iseq 
  #     errmsg("No line #{line_number} found #{place}for breakpoint.")
  #     return nil
  #   end
  #   @brkpts.add(iseq, offset, :temp => temp)
  # end
  
  # def breakpoint_offset(offset, iseq, temp=false)
  #   # FIXME: handle breakpoint conditions.
  #   unless iseq.offsetlines.keys.member?(offset)
  #     errmsg("Offset #{offset} not found in #{iseq.name} for breakpoint.")
  #     return nil
  #   end
  #   @brkpts.add(iseq, offset, :temp => temp, :type => 'offset')
  # end
  
  # Delete a breakpoint given its breakpoint number.
  # FIXME: use do_enable 
  def delete_breakpoint_by_number(bpnum, do_enable=true)
    bp = breakpoint_find(bpnum)
    return false unless bp
    delete_breakpoint(bp)
  end
  
  # Enable or disable a breakpoint given its breakpoint number.
  def en_disable_breakpoint_by_number(bpnum, do_enable=true)
    bp = breakpoint_find(bpnum)
    return false unless bp
    
    enable_disable = do_enable ? 'en' : 'dis'
    if bp.enabled? == do_enable
      errmsg('Breakpoint %d previously %sabled.' % 
             [bpnum, enable_disable])
        return false
    end
    bp.enabled = do_enable
    return true
  end
  
  def delete_breakpoint(bp)
    @brkpts.delete_by_brkpt(bp)
    return true
  end
  
end

if __FILE__ == $0
  cmdproc = Trepan::CmdProcessor.new([])
  cmdproc.breakpoint_initialize
end
