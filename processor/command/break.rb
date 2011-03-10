# Copyright (C) 2010, 2011 Rocky Bernstein <rockyb@rubyforge.net>
require 'rubygems'; require 'require_relative'
require_relative './base/cmd'

class Trepan::Command::BreakCommand < Trepan::Command

  ALIASES      = %w(b brk)
  CATEGORY     = 'breakpoints'
  NAME         = File.basename(__FILE__, '.rb')
  HELP         = <<-HELP
#{NAME} LOCATION [ {if|unless} CONDITION ]

Set a breakpoint. In the second form where CONDITIOn is given, the
condition is evaluated in the context of the position. We stop only If
CONDITION evalutes to non-false/nil and the "if" form used, or it is
false and the "unless" form used.\

Examples:
   #{NAME}
   #{NAME} 10               # set breakpoint on line 10
   #{NAME} 10 if 1 == a     # like above but only if a is equal to 1
   #{NAME} 10 unless 1 == a # like above but only if a is equal to 1
   #{NAME} me.rb:10
   #{NAME} @20   # set breakpoint VM Instruction Sequence offset 20
   #{NAME} Kernel.pp # Set a breakpoint at the beginning of Kernel.pp

See also condition, continue and "help location".
      HELP
  SHORT_HELP   = 'Set a breakpoint at a point in a method'

  # This method runs the command
  def run(args, temp=false)

    arg_str = args.size == 1 ? @proc.frame.line.to_s : @proc.cmd_argstr
    cm, line, ip, condition, negate = 
      @proc.breakpoint_position(arg_str, true)
    if cm
      event = temp ? 'tbrkpt' : 'brkpt'
      opts={:event => event, :temp => temp, :condition => condition, 
            :negate => negate}
      bp = @proc.set_breakpoint_method(cm, line, ip, opts)
      bp.set_temp! if temp
      return bp
    end
  end
  
  def ask_deferred(klass_name, which, name, line)
    if confirm('Would you like to defer this breakpoint to later?', false)
      @proc.dbgr.add_deferred_breakpoint(klass_name, which, name, line)
      msg 'Deferred breakpoint created.'
    else
      msg 'Not confirmed.'
    end
  end
end

if __FILE__ == $0
  require_relative '../mock'
  dbgr, cmd = MockDebugger::setup
  # require_relative '../../lib/trepanning'
  def run_cmd(cmd, args) 
    cmd.proc.instance_variable_set('@cmd_argstr', args[1..-1].join(' '))
    cmd.run(args)
  end

  run_cmd(cmd, [cmd.name])
  run_cmd(cmd, [cmd.name, __LINE__.to_s])

  def foo
    5 
  end
  run_cmd(cmd, [cmd.name, 'foo', (__LINE__-2).to_s])
  run_cmd(cmd, [cmd.name, 'foo'])
  run_cmd(cmd, [cmd.name, "MockDebugger::setup"])
  require 'irb'
  run_cmd(cmd, [cmd.name, "IRB.start"])
  run_cmd(cmd, [cmd.name, 'foo93'])
end
