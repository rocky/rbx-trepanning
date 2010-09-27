# Copyright (C) 2010 Rocky Bernstein <rockyb@rubyforge.net>
require 'rubygems'; require 'require_relative'
require_relative '../app/default'
class Trepan
  class CmdProcessor

    DEFAULT_SETTINGS = {
      :autoeval      => true,      # Ruby eval non-debugger commands
      :autoirb       => false,     # Go into IRB in debugger command loop
      :autolist      => false,     # Run 'list' 

      :basename      => false,     # Show basename of filenames only
      :different     => 'nostack', # stop *only* when  different position? 

      :debugdbgr     => false,     # Debugging the debugger
      :debugexcept   => true,      # Internal debugging of command exceptions
      :debugmacro    => false,     # debugging macros
      :debugskip     => false,     # Internal debugging of step/next skipping
      :debugstack    => false,     # How hidden outer debugger stack frames
      :directory     =>            # last-resort path-search for files
                    '$cdir:$cwd',  # that are not fully qualified.

      :listsize      => 10,        # Number of lines in list 
      :maxstack      => 10,        # backtrace limit
      :maxstring     => 150,       # Strings which are larger than this
                                   # will be truncated to this length when
                                   # printed
      :maxwidth       => (ENV['COLUMNS'] || '80').to_i,
      :prompt         => 'trepanx', # core part of prompt. Additional info like
                                   # debug nesting and 
      :save_cmdfile  => nil,       # If set, debugger command file to be
                                   # used on restart
      :timer         => false,     # show elapsed time between events
      :traceprint    => false,     # event tracing printing
      :tracebuffer   => false,     # save events to a trace buffer.
      :user_cmd_dir  => File.join(Trepanning::HOME_DIR, 'rbdbgr', 'command'),
                                   # User command directory

      # Rubinius-specific user variables
      :show_ip         => false,
      :show_bytecode   => false,
      :highlight       => false

    } unless defined?(DEFAULT_SETTINGS)
  end
end

if __FILE__ == $0
  # Show it:
  require 'pp'
  PP.pp(Trepan::CmdProcessor::DEFAULT_SETTINGS)
end
