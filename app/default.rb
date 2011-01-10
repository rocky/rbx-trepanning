# Copyright (C) 2010 Rocky Bernstein <rockyb@rubyforge.net>
# A place for the default settings
# This could be put elsewhere but it is expected that this will grow
# get quite large.
module Trepanning

  # I am not sure if we need to sets of hashes, but we'll start out
  # that way.

  # Default settings for a Trepan class object
  DEFAULT_SETTINGS = {
    :cmdproc_opts    => {},    # Default Trepan::CmdProcessor settings
    :core_opts       => {},    # Default Trepan::Core settings
    :delete_restore  => true,  # Delete restore profile after reading? 
    :initial_dir     => nil,   # If --cd option was given, we save it here.
    :nx              => false, # Don't run user startup file (e.g. .trepanxrc)
    :offset          => 0,     # skipping back +offset+ frames. This lets you start
                               # the debugger straight into callers method.

    # Default values used only when 'server' or 'client'
    # (out-of-process debugging)
    :port            => 1027,
    :host            => 'localhost', 

    :restart_argv    => Rubinius::OS_ARGV,
                               # Command run when "restart" is given.
    :restore_profile => nil,   # Profile used to set/restore debugger state
    :server          => false, # Out-of-process debugging?
    :skip_loader     => false, # If run via -Xdebug or trepanx
                               # command-line we need this to skip
                               # over some initial Rubinius loader
                               # commands.
  } unless defined?(DEFAULT_SETTINGS)

  # Default settings for Trepan run from the command line.
  DEFAULT_CMDLINE_SETTINGS = {
    :cmdfiles => [],  # Initialization command files to run
    :client   => false, # Attach to out-of-process program?
    :nx       => false, # Don't run user startup file (e.g. .trepanxrc)
    :output   => nil,
    :server   => false, # Out-of-process debugging?
    # Note that at most one of :server or :client can be true.
  } unless defined?(DEFAULT_CMDLINE_SETTINGS)

  DEFAULT_DEBUG_STR_SETTINGS = {
    :core_opts => {
      :cmdproc_opts => {:different => false}},
    :hide_stack => true,
  } unless defined?(DEFAULT_DEBUG_STR_SETTINGS)

  CMD_INITFILE_BASE = 
    if RUBY_PLATFORM =~ /mswin/
      # Of course MS Windows has to be different
      HOME_DIR     =  (ENV['HOME'] || 
                       ENV['HOMEDRIVE'].to_s + ENV['HOMEPATH'].to_s).to_s
      'trepanx.ini'
    else
      HOME_DIR = ENV['HOME'].to_s
      '.trepanxrc'
    end unless defined?(CMD_INITFILE_BASE)
  CMD_INITFILE = File.join(HOME_DIR, CMD_INITFILE_BASE) unless
    defined?(CMD_INITFILE)
end

if __FILE__ == $0
  # Show it:
  require 'pp'
  PP.pp(Trepanning::DEFAULT_SETTINGS)
  puts '=' * 30
  PP.pp(Trepanning::DEFAULT_CMDLINE_SETTINGS)
end
