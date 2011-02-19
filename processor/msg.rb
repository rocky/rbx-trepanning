# Copyright (C) 2010, 2011 Rocky Bernstein <rockyb@rubyforge.net>
# I/O related command processor methods
require 'rubygems'; require 'require_relative'
require_relative '../app/util'
class Trepan
  class CmdProcessor
    attr_accessor :ruby_highlighter

    def errmsg(message, opts={})
      message = safe_rep(message) unless opts[:unlimited]
      if @settings[:highlight] && defined?(Term::ANSIColor)
        message = 
          Term::ANSIColor.italic + message + Term::ANSIColor.reset 
      end
      @dbgr.intf[-1].errmsg(message)
    end

    def msg(message, opts={})
      message = safe_rep(message) unless opts[:unlimited]
      @dbgr.intf[-1].msg(message)
    end

    def msg_nocr(message, opts={})
      message = safe_rep(message) unless opts[:unlimited]
      @dbgr.intf[-1].msg_nocr(message)
    end

    def read_command()
      @dbgr.intf[-1].read_command(@prompt)
    end

    def ruby_format(text)
      return text unless settings[:highlight]
      unless @ruby_highlighter
        begin
          require 'coderay'
          require 'term/ansicolor'
          @ruby_highlighter ||= CodeRay::Duo[:ruby, :term]
          return @ruby_highlighter.encode(text)
        rescue LoadError
        end
      end
      text
    end

    def safe_rep(str)
      Util::safe_repr(str, @settings[:maxstring])
    end

    def section(message, opts={})
      message = safe_rep(message) unless opts[:unlimited]
      if @settings[:highlight] && defined?(Term::ANSIColor)
        message = 
          Term::ANSIColor.bold + message + Term::ANSIColor.reset 
      end
      @dbgr.intf[-1].msg(message)
    end

  end
end
