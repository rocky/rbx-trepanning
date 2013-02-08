# Copyright (C) 2010-2011, 2013 Rocky Bernstein <rockyb@rubyforge.net>
class Trepan

  # Call-Stack frame methods
  class Frame
    def initialize(dbgr, number, vm_location)
      @debugger = dbgr
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
                                 @vm_location.constant_scope)
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

      filename = loc.method.active_path
      filename = File.basename(filename) if opts[:basename]
      str = "#{recv} at #{filename}:#{loc.line}"
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
      line_no = @vm_location.line
      line_no == 0 ? ISeq::tail_code_line(method, next_ip) : line_no
    end

    def local_variables
      method.local_names
    end

    # Return true if frame1 and frame2 are at the same place.
    # We use this for example in detecting tail recursion.
    def location_equal(other_frame)
      # if self && other_frame 
      #   puts(self.vm_location.line, other_frame.vm_location.line, 
      #        self.vm_location.ip, other_frame.vm_location.ip, 
      #        self.vm_location.method.active_path, other_frame.vm_locaion.method.actionve_path)
      # end
      self && other_frame && self.vm_location.line == other_frame.vm_location.line &&
        self.vm_location.ip == other_frame.vm_location.ip && 
        self.vm_location.method.active_path == other_frame.vm_location.method.active_path
    end

    def method
      @vm_location.method
    end

    def scope
      @vm_location.variables
    end

    def stack_size
      @debugger.vm_locations.size
    end

    def eval?
      static = @vm_location.constant_scope
      static && static.script && static.script.eval_source
    end

    def eval_string
      return nil unless eval?
      static = @vm_location.constant_scope
      static.script.eval_source
    end

  end
end
