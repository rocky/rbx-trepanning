require 'rubygems'; require 'require_relative'
require_relative '../app/iseq'
class Trepan
  class CmdProcessor
    include Trepanning::ISeq
    def step_over_by(step)
      f = @frame
      
      ip = -1
      
      meth = f.method
      possible_line = f.line + step
      fin_ip = meth.first_ip_on_line possible_line
      
      if fin_ip == -1
        return step_to_parent
      end
      
      set_breakpoints_between(meth, f.ip, fin_ip)
    end
    
    def step_to_return_or_yield
      f = @frame
      unless f
        msg 'Unable to find frame to finish'
        return
      end
      
      meth = f.method
      ip = -1
      fin_ip = meth.lines.last
      
      set_breakpoints_on_return_between(meth, f.ip, fin_ip)
    end
    
    def step_to_parent
      f = @dbgr.frame(@frame.number + 1)
      unless f
        msg 'Unable to find frame to step to next'
        return
      end
      
      meth = f.method
      ip = f.ip
      
      bp = Trepanning::Breakpoint.for_ip(meth, ip, {:event => 'return'})
      bp.scoped!(@frame.scope)
      bp.activate
      
      return bp
    end
    
    def set_breakpoints_between(meth, start_ip, fin_ip)
      ips = goto_between(meth, start_ip, fin_ip)
      if ips.kind_of? Fixnum
        ip = ips
      else
        one, two = ips
        bp1 = Trepanning::Breakpoint.for_ip(meth, one, {:event => 'line'})
        bp2 = Trepanning::Breakpoint.for_ip(meth, two, {:event => 'line'})
        
        bp1.related_with(bp2)
        
        bp1.scoped!(@frame.scope)
        bp2.scoped!(@frame.scope)
        
        bp1.activate
        bp2.activate
        
        return bp1
      end
      
      if ip == -1
        errmsg "No place to step to"
        return nil
      end
      
      bp = Trepanning::Breakpoint.for_ip(meth, ip, {:event => 'line'})
      bp.scoped!(@frame.scope)
      bp.activate
      
      return bp
    end
    
    def set_breakpoints_on_return_between(meth, start_ip, fin_ip)
      ips = yield_or_return_between(meth, start_ip, fin_ip)
      if ips.empty?
        errmsg '"ret" or "yield_stack" opcode not found'
        return []
      end
      
      bp1 = Trepanning::Breakpoint.for_ip(meth, ips[0], 
                                          { :event => 'return',
                                            :temp  => true})
      bp1.scoped!(@frame.scope)
      bp1.activate
      result = [bp1]
      
      1.upto(ips.size-1) do |i| 
        bp2 = Trepanning::Breakpoint.for_ip(meth, ips[i], 
                                            { :event => 'return',
                                              :temp  => true})
        bp2.scoped!(@frame.scope)
        bp1.related_with(bp2)
        bp2.activate
        result << bp2
      end
      return result
    end
  end
end
