# -*- coding: utf-8 -*-
# Copyright (C) 2010 Rocky Bernstein <rockyb@rubyforge.net>
require 'rbconfig'
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

    ## dbgr.trace_filter << self.method(:debug_program)
    ## dbgr.trace_filter << Kernel.method(:load)


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
    start_opts = {:hide_level => hide_level}.merge(start_opts)
    dbgr.start(start_opts)
    Kernel::load program_to_debug

    # The dance we have to undo to restore $0 and undo the mess created
    # above.
    $0 = old_dollar_0
    ## untrace_var(:$0, dollar_0_tracker)
  end

  # Return an ARRAY which makes explicit what array is needed to pass
  # to system() to reinvoke this debugger using the same Ruby
  # interpreter.  Therefore, We want to the full path of both the Ruby
  # interpreter and the debugger file ($0). We do this so as not to
  # rely on an OS search lookup and/or the current working directory
  # not getting changed from the initial invocation.
  #
  #    Hmmm, perhaps it is better to also save the initial working
  #    directory? Yes, but on the other hand we can't assume that it 
  #    still exists so we might still need to have the full paths.
  # 
  # It is the caller's responsibility to ensure that argv is the same
  # as ARGV when the debugger was invokes.
  def explicit_restart_argv(argv)
    [ruby_path, File.expand_path($0)] + argv
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
  p explicit_restart_argv(ARGV)
end
