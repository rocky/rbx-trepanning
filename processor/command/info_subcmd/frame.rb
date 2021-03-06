# -*- coding: utf-8 -*-
require 'rubygems'; require 'require_relative'
# Copyright (C) 2010, 2011 Rocky Bernstein <rockyb@rubyforge.net>
require_relative '../base/subcmd'

class Trepan::Subcommand::InfoFrame < Trepan::Subcommand
  unless defined?(HELP)
    Trepanning::Subcommand.set_name_prefix(__FILE__, self)
    HELP = <<-EOH
#{CMD} 

Show information about the selected frame. The fields we list are:

* A source container and name (e.g. "file" or "string" and the value)
* The actual number of arguments passed in
* The 'arity' or permissible number of arguments passed it. -1 indicates
  variable number
* The frame "type", e.g. TOP, METHOD, BLOCK, EVAL, CFUNC etc.
* The return value if the frame is at a return point
* The PC offset we are currently at; May be omitted of no instruction 
  sequence

A backtrace shows roughly the same information in a more compact form.

Example form inside File.basename('foo')

Frame basename
  file  : /tmp/c-func.rb # actually location of caller
  line  : 2  # inherited from caller
  argc  : 1  # One out argument supplied: 'foo'
  arity : -1 # Variable number of args, can have up to 2 arguments.
  type  : CFUNC  (A C function)


See also: backtrace
    EOH
    MIN_ABBREV   = 'fr'.size # Note we have "info file"
    MIN_ARGS     = 0
    MAX_ARGS     = 0
    NEED_STACK   = true
    SHORT_HELP   = 'Show information about the selected frame'
  end

  def run(args)
    frame = @proc.frame
    loc   = frame.vm_location
    section "Frame %2d: #{frame.method.name}" % frame.number
    msg "  in    : #{loc.describe_receiver}#{loc.name}"
    msg "  file  : %s" % loc.method.active_path
    msg "  line  : %s" % frame.line
    # msg "  argc  : %d" % frame.argc
    msg "  arity : %d" % frame.method.arity
    # msg "  type  : %s" % frame.type
    msg "  offset: %d" % frame.ip
    # if %w(return c-return).member?(@proc.event)
    #   ret_val = Trepan::Frame.value_returned(@proc.frame, @proc.event)
    #   msg "  Return: %s" % ret_val
    # end
  end

end

if __FILE__ == $0
  # Demo it.
  require_relative '../../mock'
  cmd = MockDebugger::sub_setup(Trepan::Subcommand::InfoFrame, false)
  cmd.run(cmd.prefix)
end
