# Copyright (C) 2010, 2011 Rocky Bernstein <rockyb@rubyforge.net>
class Trepan

  # Call-Stack frame methods
  class Frame
    def initialize(debugger, number, vm_location)
      @debugger = debugger
      @number = number
      @vm_location = vm_location
    end

    attr_reader :number, :vm_location

    def run(code, filename=nil)
      eval(code, self.binding, filename)
    end

    def binding
      @binding ||= Binding.setup(@vm_location.variables,
                                 @vm_location.method,
                                 @vm_location.static_scope)
    end

    def describe(opts = {})
      if method.required_args > 0
        locals = []
        0.upto(method.required_args-1) do |arg|
          locals << method.local_names[arg].to_s
        end

        arg_str = locals.join(", ")
      else
        arg_str = ""
      end

      loc = @vm_location

      if loc.is_block
        if arg_str.empty?
          recv = "{ } in #{loc.describe_receiver}#{loc.name}"
        else
          recv = "{|#{arg_str}| } in #{loc.describe_receiver}#{loc.name}"
        end
      else
        if arg_str.empty?
          recv = loc.describe
        else
          recv = "#{loc.describe}(#{arg_str})"
        end
      end

      str = "#{recv} at #{loc.method.active_path}:#{loc.line}"
      if opts[:show_ip]
        str << " (@#{loc.ip})"
      end

      str
    end

    def file
      @vm_location.file
    end

    def ip
      @vm_location.ip
    end

    def next_ip
      @vm_location.next_ip
    end

    def line
      @vm_location.line
    end

    def local_variables
      method.local_names
    end

    def method
      @vm_location.method
    end

    def scope
      @vm_location.variables
    end

    def eval?
      static = @vm_location.static_scope
      static && static.script && static.script.eval_source
    end

    def eval_string
      return nil unless eval?
      static = @vm_location.static_scope
      static.script.eval_source
    end

  end
end
