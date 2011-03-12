# Copyright (C) 2010, 2011 Rocky Bernstein <rockyb@rubyforge.net>

# Trepan command input validation routines.  A String type is
# usually passed in as the argument to validation routines.

require 'rubygems'
require 'require_relative'
require 'linecache'

require_relative '../app/cmd_parse'
require_relative '../app/condition'
require_relative '../app/method'
require_relative '../app/validate'

require_relative 'location' # for resolve_file_with_dir
require_relative 'msg'      # for errmsg, msg

class Trepan
  class CmdProcessor

    attr_reader :dbgr_script_iseqs
    attr_reader :dbgr_iseqs

    include Trepanning::Method
    include Trepan::Validate
    ## include Trepan::ThreadHelper
    include Trepan::Condition

    def confirm(msg, default)
      @settings[:confirm] ? @dbgr.intf[-1].confirm(msg, default) : true
    end

    # Like cmdfns.get_an_int(), but if there's a stack frame use that
    # in evaluation.
    def get_an_int(arg, opts={})
      ret_value = get_int_noerr(arg)
      if !ret_value
        if opts[:msg_on_error]
          errmsg(opts[:msg_on_error])
        else
          errmsg("Expecting an integer, got: #{arg}.")
        end
        return nil
      end
      if opts[:min_value] and ret_value < opts[:min_value]
        errmsg("Expecting integer value to be at least %d; got %d." %
               [opts[:min_value], ret_value])
        return nil
      elsif opts[:max_value] and ret_value > opts[:max_value]
        errmsg("Expecting integer value to be at most %d; got %d." %
               [opts[:max_value], ret_value])
        return nil
      end
      return ret_value
    end

    unless defined?(DEFAULT_GET_INT_OPTS)
      DEFAULT_GET_INT_OPTS = {
        :min_value => 0, :default => 1, :cmdname => nil, :max_value => nil}
    end

    # If argument parameter 'arg' is not given, then use what is in
    # opts[:default]. If String 'arg' evaluates to an integer between
    # least min_value and at_most, use that. Otherwise report an
    # error.  If there's a stack frame use that for bindings in
    # evaluation.
    def get_int(arg, opts={})
      
      return default unless arg
      opts = DEFAULT_GET_INT_OPTS.merge(opts)
      val = arg ? get_int_noerr(arg) : opts[:default]
      unless val
        if opts[:cmdname]
          errmsg(("Command '%s' expects an integer; " +
                  "got: %s.") % [opts[:cmdname], arg])
        else
          errmsg('Expecting a positive integer, got: %s' % arg)
        end
        return nil
      end
      
      if val < opts[:min_value]
        if opts[:cmdname]
          errmsg(("Command '%s' expects an integer at least" +
                  ' %d; got: %d.') %
                 [opts[:cmdname], opts[:min_value], opts[:default]])
        else
          errmsg(("Expecting a positive integer at least" +
                  ' %d; got: %d') %
                 [opts[:min_value], opts[:default]])
        end
        return nil
      elsif opts[:max_value] and val > opts[:max_value]
        if opts[:cmdname]
          errmsg(("Command '%s' expects an integer at most" +
                  ' %d; got: %d.') %
                 [opts[:cmdname], opts[:max_value], val])
        else
          errmsg(("Expecting an integer at most %d; got: %d") %
                 [opts[:max_value], val])
        end
        return nil
      end
      return val
    end

    def get_int_list(args, opts={})
      args.map{|arg| get_an_int(arg, opts)}.compact
    end
    
    # Eval arg and it is an integer return the value. Otherwise
    # return nil
    def get_int_noerr(arg)
      b = @frame ? @frame.binding : nil
      val = Integer(eval(arg, b))
    rescue SyntaxError
      nil
    rescue 
      nil
    end

    def get_thread_from_string(id_or_num_str)
      if id_or_num_str == '.'
        Thread.current
      elsif id_or_num_str.downcase == 'm'
        Thread.main
      else
        num = get_int_noerr(id_or_num_str)
        if num
          get_thread(num)
        else
          nil
        end
      end
    end

    def position_to_line_and_offset(cm, filename, position, offset_type)
      case offset_type
      when :line
        vm_offset = cm.first_ip_on_line(position, -2)
        line_no   =  position
      when :offset
        line_no   = cm.line_from_ip(position)
        vm_offset = position
      when nil
        vm_offset, line_no = 
          if cm.lines[0] == -1
            [cm.lines[2], cm.lines.size > 3 ? cm.lines[3] : cm.lines[1]]
           else
            [cm.lines[0], cm.lines[1]]
          end
      else
        errmsg "Bad parse offset_type: #{offset_type.inspect}"
        return [nil, nil]
      end
      return [line_no, vm_offset]
    end

    # Parse a breakpoint position. On success return:
    #   - the CompileMethod the position is in
    #   - the line number - a Fixnum
    #   - vm_offset       - a Fixnum
    #   - the condition (by default 'true') to use for this breakpoint
    #   - true condition should be negated. Used in *condition* if/unless
    def breakpoint_position(position_str, allow_condition)
      break_cmd_parse = if allow_condition
                          parse_breakpoint(position_str)
                        else
                          parse_breakpoint_no_condition(position_str)
                        end
      return [nil] * 5 unless break_cmd_parse
      tail = [break_cmd_parse.condition, break_cmd_parse.negate]
      cm, file, position, offset_type = 
        parse_position(break_cmd_parse.position)
      if cm
        line_no, vm_offset = 
          position_to_line_and_offset(cm, file, position, offset_type)
        if vm_offset && line_no
          return [cm, line_no, vm_offset] + tail
        else
          errmsg("Unable to set breakpoint in #{cm}")
          return
        end
      end
      errmsg("Unable to get breakpoint position for #{position_str}")
      return [nil] * 5
    end

    # Return true if arg is 'on' or 1 and false arg is 'off' or 0.
    # Any other value is raises TypeError.
    def get_onoff(arg, default=nil, print_error=true)
      unless arg
        if !default
          if print_error
            errmsg("Expecting 'on', 1, 'off', or 0. Got nothing.")
          end
          raise TypeError
        end
        return default
      end
      darg = arg.downcase
      return true  if arg == '1' || darg == 'on'
      return false if arg == '0' || darg =='off'

      errmsg("Expecting 'on', 1, 'off', or 0. Got: %s." % arg.to_s) if
        print_error
      raise TypeError
    end

    include CmdParser

    def get_method(meth)
      start_binding = 
        begin
          @frame.binding
        rescue
          binding
        end
      if meth.kind_of?(String)
        meth_for_string(meth, start_binding)
      else
        begin
          meth_for_parse_struct(meth, start_binding)
        rescue NameError
          errmsg("Can't evaluate #{meth.name} to get a method")
          return nil
        end
      end
    end

    # FIXME: this is a ? method but we return 
    # the method value. 
    def method?(meth)
      get_method(meth)
    end

    # parse_position(self, arg)->(meth, filename, offset, offset_type)
    # See app/cmd_parser.kpeg for the syntax of a position which
    # should include things like:
    # Parse arg as [filename:]lineno | function | module
    # Make sure it works for C:\foo\bar.py:12
    def parse_position(info)
      info = parse_location(info) if info.kind_of?(String)
      case info.container_type
      when :fn
        unless info.container
          errmsg "Bad function parse #{info.container.inspect}"
          return
        end
        if meth = method?(info.container)
          cm = meth.executable
          return [cm, canonic_file(cm.active_path), info.position, 
                  info.position_type]
        else
          return [nil] * 4
        end
      when :file
        filename = canonic_file(info.container)
        cm = 
          if canonic_file(@frame.file) == filename 
            cm = @frame.method
            if :line == info.position_type
              find_method_with_line(cm, info.position)
            end
          else 
            LineCache.compiled_method(filename)
          end
        return cm, filename,  info.position, info.position_type
      when nil
        if [:line, :offset].member?(info.position_type)
          filename = @frame.file
          cm = @frame.method
          if :line == info.position_type
            cm = find_method_with_line(cm, info.position)
          end
          return [cm, canonic_file(filename), info.position, info.position_type]
        elsif !info.position_type
          errmsg "Can't parse #{arg} as a position"
          return [nil] * 4
        else
          errmsg "Unknown position type #{info.position_type} for location #{arg}"
          return [nil]  * 4
        end
      else
        errmsg "Unknown container type #{info.container_type} for location #{arg}"
        return [nil] * 4
      end
    end

    def parse_method(meth_str)
      begin 
        meth_for_string(meth_str, @frame.binding)
      rescue NameError
        nil
      rescue
        nil
      end
    end

    def validate_initialize
      ## top_srcdir = File.expand_path(File.join(File.dirname(__FILE__), '..'))
      ## @dbgr_script_iseqs, @dbgr_iseqs = filter_scripts(top_srcdir)
    end
  end
end

if __FILE__ == $0
  # Demo it.
  # FIXME have to pull in main for its initalize routine
  DIRNAME = File.dirname(__FILE__)
  load File.join(DIRNAME, 'main.rb')

  require_relative 'mock'
  dbgr, cmd = MockDebugger::setup('exit', false)
  cmdproc  = cmd.proc
  onoff = %w(1 0 on off)
  onoff.each { |val| puts "onoff(#{val}) = #{cmdproc.get_onoff(val)}" }
  %w(1 1E bad 1+1 -5).each do |val| 
    puts "get_int_noerr(#{val}) = #{cmdproc.get_int_noerr(val).inspect}" 
  end
  def foo; 5 end
  def cmdproc.errmsg(msg)
    puts msg
  end

  pos = cmdproc.parse_position('../../rubies/rbx-head/bin/irb')
  puts pos.inspect

  puts cmdproc.parse_position(__FILE__).inspect
  puts cmdproc.parse_position('@8').inspect
  puts cmdproc.parse_position('8').inspect
  puts cmdproc.parse_position("#{__FILE__} #{__LINE__}").inspect
  
  cmdproc.method?('cmdproc.errmsg')
  puts '=' * 40
  ['Array.map', 'Trepan::CmdProcessor.new',
   'foo', 'cmdproc.errmsg'].each do |str|
    puts "#{str} should be true: #{cmdproc.method?(str).inspect}"
  end
  puts '=' * 40
  
  # FIXME:
  # Array#foo should be false: true
  # Trepan::CmdProcessor.allocate should be false: true
  
  ['food', '.errmsg'].each do |str|
    puts "#{str} should be false: #{cmdproc.method?(str).inspect}"
  end
  puts '-' * 20

  puts "Trepan::CmdProcessor.allocate is: #{cmdproc.get_method('Trepan::CmdProcessor.allocate')}"

  # require_relative '../lib/trepanning'; debugger
  # pos = cmdproc.breakpoint_position('../processor/validate.rb', true)
  # p ['breakpoint validate', pos]

  p cmdproc.breakpoint_position('foo', true)
  p cmdproc.breakpoint_position('@0', true)
  p cmdproc.breakpoint_position("#{__LINE__}", true)
  p cmdproc.breakpoint_position("#{__FILE__}   @0", false)
  p cmdproc.breakpoint_position("#{__FILE__}:#{__LINE__}", true)
  p cmdproc.breakpoint_position("#{__FILE__} #{__LINE__} if 1 == a", true)
  p cmdproc.breakpoint_position("cmdproc.errmsg", false)
  p cmdproc.breakpoint_position("cmdproc.errmsg:@0", false)
  ### p cmdproc.breakpoint_position(%w(2 if a > b))
  p cmdproc.get_int_list(%w(1+0 3-1 3))
  p cmdproc.get_int_list(%w(a 2 3))
end
