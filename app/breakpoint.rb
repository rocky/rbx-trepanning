module Trepanning
  class Breakpoint

    attr_accessor :condition # If non-nil, this is a String to be eval'd
                             # which must be true to enter the debugger
    attr_reader   :event     # Symbol. Optional type of event associated with
                             # breakpoint.
    attr_accessor :hits      # Fixnum. The number of timea a breakpoint
                             # has been hit (with a true condition). Do
                             # we want to (also) record hits independent
                             # of the condition?
    attr_reader   :id        # Fixnum. Name of breakpoint

    @@next_id = 1

    BRKPT_DEFAULT_SETTINGS = {
      :condition => 'true',
      :enabled   => 'true',
      :temp      =>  false,
      :event     =>  :Unknown,
    } unless defined?(BRKPT_DEFAULT_SETTINGS)

    def self.for_ip(exec, ip, opts={})
      name = opts[:name] || :anon
      line = exec.line_from_ip(ip)

      Breakpoint.new(name, exec, ip, line, nil, opts)
    end

    def initialize(name, method, ip, line, id=nil, opts = {})
      @descriptor = name
      @id = id
      @method = method
      @ip = ip
      @line = line
      @for_step = false
      @paired_bp = nil

      opts = BRKPT_DEFAULT_SETTINGS.merge(opts)
      opts.keys.each do |key|
        self.instance_variable_set('@'+key.to_s, opts[key])
      end

      @hits = 0
      # unless @id
      #   @id = @@next_id 
      #   @@next_id += 1
      # end

      @set = false
    end

    attr_reader :method, :ip, :line, :paired_bp, :descriptor

    def for_step!
      @temp = true
      @for_step = true
    end

    def set_temp!
      @temp = true
    end

    def for_step?
      @for_step
    end

    def paired_with(bp)
      @paired_bp = bp
    end

    def activate
      @set = true
      @method.set_breakpoint @ip, self
    end

    def hit!
      return unless @temp

      remove!

      @paired_bp.remove! if @paired_bp
    end

    # def condition?(bind)
    #   if eval(@condition, bind)
    #     if @ignore > 0
    #       @ignore -= 1
    #       return false
    #     else
    #       @hits += 1
    #       return true
    #     end
    #   else
    #     return false
    #   end
    # end

    def delete!
      remove!
    end

    def describe
      "#{descriptor} - #{location}"
    end

    def disable
      @enabled = false
    end

    def enabled
      @enabled = true
    end

    def enabled=(bool)
      @enabled = bool
    end

    def enabled?
      @enabled
    end

    # Return a one-character "icon" giving the state of the breakpoint
    # 't': temporary breakpoint
    # 'B': enabled breakpoint
    # 'b': disabled breakpoint
    def icon_char
      temp? ? 't' : (enabled? ? 'B' : 'b')
    end

    def location
      "#{@method.active_path}:#{@line} (@#{ip})"
    end

    def remove!
      return unless @set

      @set = false
      @method.clear_breakpoint(@ip)
    end

    def temp?
      @temp
    end

  end

  class DeferredBreakpoint
    def initialize(debugger, frame, klass, which, name, line=nil, list=nil)
      @debugger = debugger
      @frame = frame
      @klass_name = klass
      @which = which
      @name = name
      @line = line
      @list = list
    end

    def descriptor
      "#{@klass_name}#{@which}#{@name}"
    end

    def resolve!
      begin
        klass = @frame.run(@klass_name)
      rescue NameError
        return false
      end

      begin
        if @which == "#"
          meth = klass.instance_method(@name)
        else
          meth = klass.method(@name)
        end
      rescue NameError
        return false
      end

      @debugger.processor "Resolved breakpoint for #{@klass_name}#{@which}#{@name}"

      @debugger.processor.set_breakpoint_method descriptor, meth, @line

      return true
    end

    def describe
      "#{descriptor} - unknown location (deferred)"
    end

    def delete!
      if @list
        @list.delete self
      end
    end
  end
end

if __FILE__ == $0
  method = Rubinius::CompiledMethod.of_sender
  bp = Trepanning::Breakpoint.new '<start>', method, 1, 2, 0
  %w(describe location icon_char hits temp? enabled? condition).each do |field|
    puts "#{field}: #{bp.send(field.to_sym)}"
  end
end
