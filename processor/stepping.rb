require 'rubygems'; require 'require_relative'
require_relative '../app/iseq'
require_relative 'virtual'
class Trepan
  class CmdProcessor < VirtualCmdProcessor

    def stepping_initialize
      @step_brkpts  = []
    end

    def stepping_breakpoint_finalize
      @step_brkpts.each do |bp| 
        bp.remove!
      end
    end

    def remove_step_brkpt
      return unless @step_bp
      @step_brkpts = @step_brkpts.select do |bp| 
        (bp != @step_bp) && bp.active?
      end
      @step_bp.remove!
    end

    # It might be interesting to allow stepping within a parent frame
    def step_over_by(step, frame=@top_frame)
      
      f = frame
      
      meth = f.method
      possible_line = f.line + step
      next_ip = f.next_ip == f.ip ? f.next_ip + 1 : f.next_ip
      # BUGGY: remove after writing a decent test case for this.
      # See beginning of rbx-require/require_relative.
      fin_ip = meth.first_ip_on_line_after(possible_line, f.next_ip)
      # fin_ip = meth.first_ip_on_line_after(possible_line, next_ip)
      
      unless fin_ip
        return step_to_parent('line')
      end

      set_breakpoints_between(meth, f.next_ip, fin_ip)
    end
    
    def step_to_return_or_yield
      f = @frame
      unless f
        msg 'Unable to find frame to finish'
        return
      end
      
      meth = f.method
      fin_ip = meth.lines.last
      
      set_breakpoints_on_return_between(meth, f.next_ip, fin_ip)
    end

    def step_to_parent(event='return')
      f = parent_frame
      unless f
        errmsg "Unable to find parent frame to step to next"
        return nil 
      end
      meth = f.method
      ip   = f.ip

      bp = Breakpoint.for_ip(meth, ip, {:event => event, :temp => true})
      bp.scoped!(parent_frame.scope)
      bp.activate
      
      return bp
    end

    # Sets temporary breakpoints in met between start_ip and fin_ip.
    # We also set a temporary breakpoint in the caller.
    def set_breakpoints_between(meth, start_ip, fin_ip)
      opts = {:event => 'line', :temp  => true}
      ips = ISeq.goto_between(meth, start_ip, fin_ip)
      bps = []
      
      if ips.kind_of? Fixnum
        if ips == -1
          errmsg "No place to step to"
          return nil
        elsif ips == -2
          bps << step_to_parent(event='line')
          ips = []
        else
          ips = [ips]
        end
      end

      msg "temp ips: #{ips.inspect}" if settings[:debugstep]
      ips.each do |ip|
        bp = Breakpoint.for_ip(meth, ip, opts)
        bp.scoped!(@frame.scope)
        bp.activate
        bps << bp
      end
      @step_brkpts += bps
      first_bp = bps[0]
      bps[1..-1].each do |bp| 
        first_bp.related_with(bp) 
      end
      return first_bp
    end
    
    def set_breakpoints_on_return_between(meth, start_ip, fin_ip)
      ips = ISeq::yield_or_return_between(meth, start_ip, fin_ip)
      if ips.empty?
        errmsg '"ret" or "yield_stack" opcode not found'
        return []
      end
      
      bp1 = Breakpoint.for_ip(meth, ips[0], 
                              { :event => 'return',
                                :temp  => true})
      bp1.scoped!(@frame.scope)
      bp1.activate
      result = [bp1]
      
      1.upto(ips.size-1) do |i| 
        bp2 = Breakpoint.for_ip(meth, ips[i], 
                                { :event => 'return',
                                  :temp  => true})
        bp2.scoped!(@frame.scope)
        bp1.related_with(bp2)
        bp2.activate
        result << bp2
      end
      @step_brkpts += result
      return result
    end
  end
end
