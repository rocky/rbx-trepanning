require 'rubygems'; require 'require_relative'
require_relative 'base/cmd'
require_relative '../../app/breakpoint'

class Trepan::Command::NextCommand < Trepan::Command

  ALIASES      = %w(n)
  CATEGORY     = 'running'
  HELP= <<-HELP
Attempt to continue execution and stop at the next line. If there is
a conditional branch between the current position and the next line,
execution is stopped within the conditional branch instead.

The optional argument is a number which specifies how many lines to
attempt to skip past before stopping execution.

If the current line is the last in a method, execution is stopped
at the current position of the caller.
      HELP
  NAME         = File.basename(__FILE__, '.rb')
  NEED_RUNNING = true
  SHORT_HELP   =  'Move to the next line or conditional branch'

  def run(args)
    if args.size == 1
      step = 1
    else
      step_str = args[1]
      opts = {
        :msg_on_error => 
        "The 'next' command argument must eval to an integer. Got: %s" % 
        step_str,
        :min_value => 1
      }
      step = @proc.get_an_int(step_str, opts)
      return unless step
    end
    
    step_over_by(step)
    @proc.dbgr.listen
  end
  
  def step_over_by(step)
    f = @proc.frame
    
    ip = -1
    
    exec = f.method
    possible_line = f.line + step
    fin_ip = exec.first_ip_on_line possible_line
    
    if fin_ip == -1
      return step_to_parent
    end
    
    set_breakpoints_between(exec, f.ip, fin_ip)
  end
  
  def step_to_parent
    f = @proc.dbgr.frame(@proc.frame.number + 1)
    unless f
      info "Unable to find frame to step to next"
      return
    end
    
    exec = f.method
    ip = f.ip
    
    bp = Trepanning::BreakPoint.for_ip(exec, ip, {:event => :Return})
    bp.for_step!
    bp.activate
    
    return bp
  end
  
  def set_breakpoints_between(exec, start_ip, fin_ip)
    ips = goto_between(exec, start_ip, fin_ip)
    if ips.kind_of? Fixnum
      ip = ips
    else
      one, two = ips
      bp1 = Trepanning::BreakPoint.for_ip(exec, one, {:event => :Statement})
      bp2 = Trepanning::BreakPoint.for_ip(exec, two, {:event => :Statement})
      
      bp1.paired_with(bp2)
      bp2.paired_with(bp1)
      
      bp1.for_step!
      bp2.for_step!
      
      bp1.activate
      bp2.activate
      
      return bp1
    end
    
    if ip == -1
      error "No place to step to"
      return nil
    end
    
    bp = Trepanning::BreakPoint.for_ip(exec, ip, {:event => :Statement})
    bp.for_step!
    bp.activate
    
    return bp
  end
  
  def next_interesting(exec, ip)
    pop = Rubinius::InstructionSet.opcodes_map[:pop]
    
    if exec.iseq[ip] == pop
      return ip + 1
    end
    
    return ip
  end
  
  def goto_between(exec, start, fin)
    goto = Rubinius::InstructionSet.opcodes_map[:goto]
    git  = Rubinius::InstructionSet.opcodes_map[:goto_if_true]
    gif  = Rubinius::InstructionSet.opcodes_map[:goto_if_false]
    
    iseq = exec.iseq
    
    i = start
    while i < fin
      op = iseq[i]
      case op
      when goto
        return next_interesting(exec, iseq[i + 1]) # goto target
      when git, gif
        return [next_interesting(exec, iseq[i + 1]),
                next_interesting(exec, i + 2)] # target and next ip
      else
        op = Rubinius::InstructionSet[op]
        i += (op.arg_count + 1)
      end
    end
    
    return next_interesting(exec, fin)
  end
  
end

if __FILE__ == $0
  require_relative '../mock'
  name = File.basename(__FILE__, '.rb')
  dbgr, cmd = MockDebugger::setup(name)
  # [%w(n 5), %w(next 1+2), %w(n foo)].each do |c|
  #   dbgr.core.step_count = 0
  #   cmd.proc.leave_cmd_loop = false
  #   result = cmd.run(c)
  #   puts 'Run result: %s' % result
  #   puts 'step_count %d, leave_cmd_loop: %s' % [dbgr.core.step_count,
  #                                               cmd.proc.leave_cmd_loop]
  # end
  # [%w(n), %w(next+), %w(n-)].each do |c|
  #   dbgr.core.step_count = 0
  #   cmd.proc.leave_cmd_loop = false
  #   result = cmd.run(c)
  #   puts cmd.proc.different_pos
  # end
end
