require 'rubygems'; require 'require_relative'
require_relative './base/cmd'

class RBDebug::Command::SetBreakPoint < RBDebug::Command
  pattern "b", "break", "brk"
  help "Set a breakpoint at a point in a method"
  ext_help <<-HELP
The breakpoint must be specified using the following notation:
  Klass[.#]method:line

Thus, to set a breakpoint for the instance method pop in
Array on line 33, use:
  Array#pop:33

To breakpoint on class method start of Debugger line 4, use:
  RBDebug.start:4
      HELP

  def run(args, temp=false)
    m = /([A-Z]\w*(?:::[A-Z]\w*)*)([.#])(\w+)(?:[:](\d+))?/.match(args)
    unless m
      error "Unrecognized position: '#{args}'"
      return
    end
    
    klass_name = m[1]
    which = m[2]
    name  = m[3]
    line =  m[4] ? m[4].to_i : nil
    
    begin
      klass = run_code(klass_name)
    rescue NameError
      error "Unable to find class/module: #{m[1]}"
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
    
    bp = @debugger.set_breakpoint_method args.strip, method, line
    
    bp.set_temp! if temp
    
    return bp
  end
  
  def ask_deferred(klass_name, which, name, line)
    answer = ask "Would you like to defer this breakpoint to later? [y/n] "
    
    if answer.strip.downcase[0] == ?y
      @debugger.add_deferred_breakpoint(klass_name, which, name, line)
      info "Deferred breakpoint created."
    end
  end
end

