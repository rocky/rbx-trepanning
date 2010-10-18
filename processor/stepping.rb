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
    
    def step_to_return
      f = @frame
      unless f
        msg 'Unable to find frame to finish'
        return
      end
      
      meth = f.method
      ip = -1
      fin_ip = meth.lines.last
      
      set_breakpoints_between(meth, f.ip, fin_ip)
      bp = Trepanning::Breakpoint.for_ip(meth, ip, {:event => 'return'})
      bp.for_step!
      bp.activate
      
      return bp
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
      bp.for_step!
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
        
        bp1.paired_with(bp2)
        bp2.paired_with(bp1)
        
        bp1.for_step!
        bp2.for_step!
        
        bp1.activate
        bp2.activate
        
        return bp1
      end
      
      if ip == -1
        errmsg "No place to step to"
        return nil
      end
      
      bp = Trepanning::Breakpoint.for_ip(meth, ip, {:event => 'line'})
      bp.for_step!
      bp.activate
      
      return bp
    end
    
    def set_breakpoints_on_return_between(meth, start_ip, fin_ip)
      ips = return_between(meth, start_ip, fin_ip)
      bp1 = nil
      0.upto(ips.size-1) do |i| 
        bp1 = Trepanning::Breakpoint.for_ip(meth, i, {:event => 'return'})
        # FIXME handle pairing
        # bp2 = Trepanning::Breakpoint.for_ip(meth, two, {:event => 'return'})
        # bp1.paired_with(bp2)
        # bp2.paired_with(bp1)
        
        bp1.for_step!
        # bp2.for_step!
        
        # bp1.activate
        # bp2.activate
        return bp1
      end
      
      if nil == bp1
        errmsg 'Return not found'
        return nil
      end
      
      return bp1
    end
  end
end
