require 'rubygems'; require 'require_relative'
require_relative './base/cmd'

class Trepan::Command::SetBreakPointCommand < Trepan::Command

  ALIASES      = %w(b brk)
  CATEGORY     = 'breakpoints'
  NAME         = File.basename(__FILE__, '.rb')

  HELP         = <<-HELP
The breakpoint must be specified using the following notation:
  Klass[.#]method:line

Thus, to set a breakpoint for the instance method pop in
Array on line 33, use:
  Array#pop:33

To breakpoint on class method start of Trepan line 4, use:
  Trepan.start:4
      HELP
  SHORT_HELP   = 'Set a breakpoint at a point in a method'

  def run(args, temp=false)
    arg_str = args[1..-1].join(' ')
    m = /([A-Z]\w*(?:::[A-Z]\w*)*)([.#])(\w+)(?:[:](\d+))?/.match(arg_str)
    unless m
      errmsg "Unrecognized position: '#{arg_str}'"
      return
    end
    
    klass_name = m[1]
    which = m[2]
    name  = m[3]
    line =  m[4] ? m[4].to_i : nil
    
    begin
      klass = run_code(klass_name)
    rescue NameError
      errmsg "Unable to find class/module: #{m[1]}"
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
      error "Unable to find method '#{name}' in #{klass}"
      ask_deferred klass_name, which, name, line
      return
    end
    
    bp = @proc.dbgr.set_breakpoint_method args.strip, method, line
    
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

