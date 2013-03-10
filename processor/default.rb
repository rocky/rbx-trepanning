# Copyright (C) 2010-2011, 2013 Rocky Bernstein <rockyb@rubyforge.net>
require 'rubygems'; require 'require_relative'
require_relative '../app/default'
require_relative 'virtual'
class Trepan::CmdProcessor < Trepan::VirtualCmdProcessor

  computed_displaywidth = (ENV['COLUMNS'] || '80').to_i
  computed_displaywidth = 80 unless computed_displaywidth >= 10

  DEFAULT_SETTINGS = {
    :abbrev        => true,       # Allow abbreviations of debugger commands?
    :autoeval      => true,       # Ruby eval non-debugger commands
    :autoirb       => false,      # Go into IRB in debugger command loop
    :autolist      => false,      # Run 'list' 
    
    :basename      => false,      # Show basename of filenames only
    :confirm       => true,       # Confirm potentially dangerous operations?
    :different     => 'nostack',  # stop *only* when  different position? 
    
    :debugdbgr     => false,      # Debugging the debugger
    :debugexcept   => true,       # Internal debugging of command exceptions
    :debugmacro    => false,      # debugging macros
    :debugskip     => false,      # Internal debugging of step/next skipping
    :directory     =>             # last-resort path-search for files
                    '$rbx:$cdir:$cwd',  # that are not fully qualified.

    :hidestack     => nil,        # Fixnum. How many hidden outer
                                  # debugger stack frames to hide?
                                  # nil or -1 means compute value. 0
                                  # means hide none. Less than 0 means show
                                  # all stack entries.
    :hightlight    => false,      # Use terminal highlight? 
    
    :maxlist       => 10,         # Number of source lines to list 
    :maxstack      => 10,         # backtrace limit
    :maxstring     => 150,        # Strings which are larger than this
                                  # will be truncated to this length when
                                  # printed
    :maxwidth       => computed_displaywidth,
    :prompt         => 'trepanx', # core part of prompt. Additional info like
                                  # debug nesting and thread name is fixed
                                  # and added on.
    :reload         => false,     # Reread source file if we determine
                                  # it has changed?
    :save_cmdfile  => nil,        # If set, debugger command file to be
                                  # used on restart
    :timer         => false,      # show elapsed time between events
    :traceprint    => false,      # event tracing printing
    :tracebuffer   => false,      # save events to a trace buffer.
    :user_cmd_dir  => File.join(%W(#{Trepan::HOME_DIR} trepanx command)),
                                  # User command directory

    # Rubinius-specific user variables
    :show_ip         => false,
    :show_bytecode   => false,
    
    } unless defined?(CmdProcessor::DEFAULT_SETTINGS)
end

if __FILE__ == $0
  # Show it:
  require 'pp'
  PP.pp(Trepan::CmdProcessor::DEFAULT_SETTINGS)
end
