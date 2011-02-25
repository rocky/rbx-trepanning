# Copyright (C) 2010 Rocky Bernstein <rockyb@rubyforge.net>
require 'rubygems'; require 'require_relative'
require_relative './base/cmd'

class Trepan::Command::SetBreakpointCommand < Trepan::Command

  ALIASES      = %w(b brk)
  CATEGORY     = 'breakpoints'
  NAME         = File.basename(__FILE__, '.rb')
  HELP         = <<-HELP
#{NAME} 
#{NAME} [line number|offset]
#{NAME} Class[.#]method[:line-or-offset]

Sets a breakpoint. In the first form, a breakpoint is set at the
current line you are stopped at. In the second form, you give a line
number or an offset.  An offset is a number that is prefaced with 'O'
or 'o' and represents a Rubinius VM PC offset. 

The current method name is used for the start of the search. If a line
number is given and the line number is not found in that method,
enclosing scopes are searched for the line.

The last form is the most explicit. Use '#' to specify an instance
method and '.' to specify a class method. If a line number or offset
is omitted, we use the first line of the method.

Examples:

  #{NAME}     # set breakpoint at the current line
  #{NAME} 5   # set breakpoint on line 5
  #{NAME} O5  # set breakpoint at offset 5
  #{NAME} o5  # same as above
  #{NAME} Array#pop::3 # Set break at instance method 'pop' in Array, line 3
  #{NAME} Trepan.start:3  # Set break in class method 'start' of Trepan, line 3
  #{NAME} Trepan.start:o3 # Same as above but at offset 3, not line 3.
  #{NAME} Trepan.start    # Set break in class method 'start' of Trepan

See also 'tbreak', 'info breakpoint', and 'delete'. 
      HELP
  SHORT_HELP   = 'Set a breakpoint at a point in a method'

  def run(args, temp=false)
    arg_str = args[1..-1].join(' ')

    describe, klass_name, which, name, line, ip = 
      @proc.breakpoint_position(args[1..-1])
    event = temp ? 'tbrkpt' : 'brkpt'
    opts={:event => event, :temp => temp}      
    if name.kind_of?(Rubinius::CompiledMethod)
      bp = @proc.set_breakpoint_method(describe, name, line, ip, opts)
    else
      return unless klass_name
    
      begin
        klass = @proc.debug_eval(klass_name, settings[:maxstring])
      rescue NameError
        errmsg "Unable to find class/module: #{klass_name}"
        ask_deferred klass_name, which, name, line
        return
      end
      
      begin
        if which == "#"
          method = klass.instance_method(name)
        else
          method = klass.method(name)
        end
      rescue NameError
        errmsg "Unable to find method '#{name}' in #{klass}"
        ask_deferred klass_name, which, name, line
        return
      end

      bp = @proc.set_breakpoint_method(arg_str.strip, method, line, ip, opts)
    end
      
    bp.set_temp! if temp
    return bp
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
  cmd.run([cmd.name])
  # require 'trepanning'
  # Trepan.start(:set_restart => true)
  cmd.run([cmd.name, __LINE__.to_s])
  cmd.run([cmd.name, 'foo'])
  cmd.run([cmd.name, "MockDebugger::setup"])
  require 'irb'
  cmd.run([cmd.name, "IRB.start"])
end
