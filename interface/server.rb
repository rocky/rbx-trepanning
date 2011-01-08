# -*- coding: utf-8 -*-
# Copyright (C) 2011 Rocky Bernstein <rockyb@rubyforge.net>

# Our local modules
require 'rubygems'; require 'require_relative'
require_relative 'base_intf'
require_relative 'comcodes'
require_relative '../io/input'

# Mtcpserver  = import_relative('tcpserver', '..io', 'pydbgr')
# Mfifoserver = import_relative('fifoserver', '..io', 'pydbgr')
# Mmisc       = import_relative('misc', '..', 'pydbgr')

# Interface for debugging a program but having user control
# reside outside of the debugged process, possibly on another
# computer
class Trepan::ServerInterface < Trepan::Interface

  include Trepanning::RemoteCommunication

  DEFAULT_INIT_CONNECTION_OPTS = {
    :io => 'TCP'
  } unless defined?(DEFAULT_INIT_CONNECTION_OPTS)

  def initialize(inout=nil, out=nil, connection_opts={})

    @opts = DEFAULT_INIT_CONNECTION_OPTS.merge(connection_opts)

    at_exit { finalize }
    @inout = 
      if inout
        inout
      else
        server_type = @opts[:io]
        # FIXME: complete this.
        # if 'FIFO' == server_type
        #     FIFOServer.new
        # else
        #     TCPServer.new
        # end
      end
    # For Compatability 
    @output = inout
    @input  = inout
    @interactive = true # Or at least so we think initially
  end
  
  # Closes both input and output
  def close
    @inout.close if @inout
  end
  
  # Called when a dangerous action is about to be done to make sure
  # it's okay. `prompt' is printed; user response is returned.
  def confirm(prompt, default)
    while true
      begin
        write_confirm(prompt, default)
        reply = self.readline('').strip().lower()
      rescue EOFError
        return default
      end
      if %w(y yes).member?(reply)
        return true
      elsif %w(n no).member?(reply)
        return false
      else
        msg("Please answer y or n.")
      end
    end
    return default
  end
  
  # Common routine for reporting debugger error messages.
  def errmsg(str, prefix="** ")
    msg("%s%s" % [prefix, str])
  end
  
  # print exit annotation
  def finalize(last_wishes=QUIT)
    if self.is_connected()
      self.inout.writeline(last_wishes)
    end
    close
  end
  
  # Return True if we are connected
  def is_connected
    'connected' == @inout.state
  end
    
  # used to write to a debugger that is connected to this
  # server; `str' written will have a newline added to it
  def msg(msg)
    @inout.writeline(PRINT + msg)
  end

  # used to write to a debugger that is connected to this
  # server; `str' written will not have a newline added to it
  def msg_nocr(msg)
    @inout.write(PRINT +  msg)
  end
  
  def read_command(prompt)
    readline(prompt)
  end
  
  def read_data
    @inout.read_dat
  end
  
  def readline( prompt, add_to_history=true)
    if prompt
      write_prompt(prompt)
    end
    coded_line = @inout.read_msg()
    @read_ctrl = coded_line[0]
    coded_line[1..-1]
  end
  
  # Return connected
  def state
    @inout.state
  end
  
  def write_prompt(prompt)
    return @inout.writeline(PROMPT + prompt)
  end
  
  def write_confirm(prompt, default)
    if default
      code = CONFIRM_TRUE
    else
      code = CONFIRM_FALSE
    end
    @inout.writeline(code + prompt)
  end
end
    
# Demo
if __FILE__ == $0
  intf = Trepan::ServerInterface.new
end
