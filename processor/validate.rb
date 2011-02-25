# Copyright (C) 2010, 2011 Rocky Bernstein <rockyb@rubyforge.net>

# Trepan command input validation routines.  A String type is
# usually passed in as the argument to validation routines.

require 'rubygems'
require 'require_relative'
require 'linecache'

require_relative '../app/condition'
require_relative '../app/method'
require_relative '../app/method_name'
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

    def parse_num_or_offset(position_str)
      err_str = "argument '%s' does not seem to be an integer" % 
        position_str.dup
      use_offset = 
        if position_str.size > 0 && position_str[0] == '@'
          err_str << 'or an offset.'
          position_str[0] = ''
          true
        else
          err_str << '.'
          false
        end
      opts = {
        :msg_on_error => err_str,
        :min_value => 0 
      }
      position = get_an_int(position_str, opts)
      [position, use_offset]
    end

    # Parse a breakpoint position. On success return
    #   - a string "description" 
    #   - the method the position is in - a CompiledMethod or a String
    #   - the line - a Fixnum
    #   - whether the position is an instance or not
    # On failure, an error message is shown and we return nil.
    def breakpoint_position(args)
      ip = nil
      if args.size == 0
        args = [frame.line.to_s]
      end
      if args[0] == 'main.__script__'
        if args.size > 2
          errmsg 'Expecting only a line number'
          return nil
        elsif args.size == 2
          ip, line = line_or_ip(args[1])
          unless line || ip
            errmsg ("Expecting a line or an IP offset number")
            return nil 
          end
        else
          ip, line = nil, nil
        end
        return [args.join(' '), 'self', '.', '__script__', line, ip]
      elsif args.size == 1
        meth = parse_method(args[0])
        if meth
          cm = meth.executable
          return [args[0], nil, true, cm, cm.lines[1], cm.lines[0]]
        else
          m = /([A-Z]\w*(?:::[A-Z]\w*)*)([.])(\w+[!?=]?)(?:[:]@?(\d+))?/.match(args[0])
          if m
            if m[4]
              return [m[0], m[1], m[2], m[3], nil, m[5] ? m[5].to_i : nil]
            else
              return [m[0], m[1], m[2], m[3], (m[4] ? m[4].to_i : nil), nil]
            end
          else
            ip, line = line_or_ip(args[0])
            unless line || ip
              errmsg ("Expecting a line or an IP offset number")
              return nil 
            end
            if line
              meth = find_method_with_line(frame.method, line)
              unless meth
                errmsg "Cannot find method location for line #{line}"
                return nil 
              end
              return [meth.name.to_s, nil, '#', meth, line, nil]
            elsif valid_ip?(frame.method, ip)
              return [args.join(' '), meth.class, '#', frame.method, nil, ip]
            else
              errmsg 'Cannot parse breakpoint location'
              return nil
            end
            
            return ["#{meth.describe}", nil, '#', meth, line, nil]
          end
        end
      end
      errmsg 'Cannot parse breakpoint location'
      return nil
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

    def get_method(method_string)
      start_binding = 
        begin
          @frame.binding
        rescue
          binding
        end
      meth_for_string(method_string, start_binding)
    end

    # FIXME: this is a ? method but we return 
    # the method value. 
    def method?(method_string)
      begin
        get_method(method_string)
      rescue Citrus::ParseError
        return false
      rescue NameError
        return false
      end
    end

    # parse_position(self, arg)->(fn, container, lineno)
    # 
    # Parse arg as [filename:]lineno | function | module
    # Make sure it works for C:\foo\bar.py:12
    def parse_position(arg, old_mod=nil, allow_offset = false)
      if method?(arg)
        # FIXME: DRY This code with the code in the 'else'
        mf, container, lineno = parse_position_one_arg(arg, old_mod, false, allow_offset)
        return nil, nil, nil unless container
        filename = canonic_file(arg) 
      else
        colon = arg.rindex(':') 
        if colon
          # First handle part before the colon
          arg1 = arg[0...colon].rstrip
          lineno_str = arg[colon+1..-1].lstrip
          mf, container, lineno = parse_position_one_arg(arg1, old_mod, false, allow_offset)
          return nil, nil, nil unless container
          filename = canonic_file(arg1) 
          # Next handle part after the colon
          val = get_an_int(lineno_str)
          lineno = val if val
        else
          mf, container, lineno = parse_position_one_arg(arg, old_mod, true, allow_offset)
        end
      end
      
      return mf, container, lineno
    end
    
    # parse_position_one_arg(self,arg)->(module/function, container, lineno)
    #
    # See if arg is a line number, function name, or module name.
    # Return what we've found. nil can be returned as a value in
    # the triple.
    def parse_position_one_arg(arg, old_mod=nil, show_errmsg=true, allow_offset=false)
      name, filename = nil, nil, nil
      begin
        # First see if argument is an integer
        lineno    = Integer(arg)
      rescue
      else
        filename  = @frame.file
        return nil, canonic_file(filename), lineno
      end

      # How about a method name?
      if meth = parse_method(arg)
        cm = meth.executable
        return arg, canonic_file(cm.active_path), cm.lines[1]
      end

      # Next see if argument is a file name 
      if LineCache::cached?(arg)
        return nil, canonic_file(arg), 1 
      elsif File.readable?(arg)
        return nil, canonic_file(arg), 1 
      end

      if show_errmsg
        unless (allow_offset && arg.size > 0 && arg[0] == '@')
          errmsg("#{arg} is not a line number, filename or method " +
                 "we can get location information about")
        end
      end
      return nil, nil, nil
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
  proc  = cmd.proc
  onoff = %w(1 0 on off)
  onoff.each { |val| puts "onoff(#{val}) = #{proc.get_onoff(val)}" }
  %w(1 1E bad 1+1 -5).each do |val| 
    puts "get_int_noerr(#{val}) = #{proc.get_int_noerr(val).inspect}" 
  end
  def foo; 5 end
  def proc.errmsg(msg)
    puts msg
  end
  puts proc.parse_position_one_arg('tmpdir.rb').inspect
  
  puts '=' * 40
  ['Array.map', 'Trepan::CmdProcessor.new',
   'foo', 'proc.errmsg'].each do |str|
    puts "#{str} should be true: #{proc.method?(str).inspect}"
  end
  puts '=' * 40
  
  # FIXME:
  # Array#foo should be false: true
  # Trepan::CmdProcessor.allocate should be false: true
  
  ['food', '.errmsg'].each do |str|
    puts "#{str} should be false: #{proc.method?(str).inspect}"
  end
  puts '-' * 20
  p proc.breakpoint_position(%w(@0))
  p proc.breakpoint_position(%w(1))
  p proc.breakpoint_position(%w(__LINE__))
  # p proc.breakpoint_position(%w(2 if a > b))
  p proc.get_int_list(%w(1+0 3-1 3))
  p proc.get_int_list(%w(a 2 3))
end
