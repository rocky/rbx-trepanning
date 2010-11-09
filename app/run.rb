# -*- coding: utf-8 -*-
# Copyright (C) 2010 Rocky Bernstein <rockyb@rubyforge.net>
require 'rbconfig'
require 'rubygems'; require 'require_relative'
module Trepanning

  :module_function # All functions below are easily publically accessible

  # Given a Ruby interpreter and program we are to debug, debug it.
  # The caller must ensure that ARGV is set up to remove any debugger
  # arguments or things that the debugged program isn't supposed to
  # see.  FIXME: Should we make ARGV an explicit parameter?
  def debug_program(dbgr, ruby_path, program_to_debug, start_opts={})

    # Make sure Ruby script syntax checks okay.
    # Otherwise we get a load message that looks like trepanning has 
    # a problem. 
    output = `#{ruby_path} -c #{program_to_debug.inspect} 2>&1`
    if $?.exitstatus != 0 and RUBY_PLATFORM !~ /mswin/
      puts output
      exit $?.exitstatus 
    end
    # print "\032\032starting\n" if Trepan.annotate and Trepan.annotate > 2

    ## FIXME: put in fn.
    m = self.method(:debug_program).executable.inspect
    dbgr.processor.ignore_methods[m]='step'

    # m = Kernel.method(:load).executable.inspect
    # dbgr.processor.ignore_methods[m]='step'

    # Any frame from us or below should be hidden by default.
    hide_level = Rubinius::VM.backtrace(0, true).size+1

    old_dollar_0 = $0

    # Without the dance below to set $0, setting it to a signifcantly
    # longer value will truncate it in some OS's. See
    # http://www.ruby-forum.com/topic/187083
    $progname = program_to_debug
    alias $0 $progname
    ## dollar_0_tracker = lambda {|val| $program_name = val} 
    ## trace_var(:$0, dollar_0_tracker)

    ## FIXME: we gets lots of crap before we get to the real stuff.
    start_opts = {
      :skip_loader => true
    }.merge(start_opts)
    dbgr.start(start_opts)
    Kernel::load program_to_debug

    # The dance we have to undo to restore $0 and undo the mess created
    # above.
    $0 = old_dollar_0
    ## untrace_var(:$0, dollar_0_tracker)
  end

  # Path name of Ruby interpreter we were invoked with.
  def ruby_path
    File.join(%w(bindir RUBY_INSTALL_NAME).map{|k| RbConfig::CONFIG[k]})
  end
  module_function :ruby_path

  # Do a shell-like path lookup for prog_script and return the results.
  # If we can't find anything return prog_script.
  def whence_file(prog_script)
    if prog_script.index(File::SEPARATOR)
      # Don't search since this name has path separator components
      return prog_script
    end
    for dirname in ENV['PATH'].split(File::PATH_SEPARATOR) do
      prog_script_try = File.join(dirname, prog_script)
      return prog_script_try if File.readable?(prog_script_try)
    end
    # Failure
    return prog_script
  end
end

if __FILE__ == $0
  # Demo it.
  include  Trepanning
  puts whence_file('irb')
  puts whence_file('probably-does-not-exist')
  puts ruby_path
end
