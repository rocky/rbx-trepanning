# -*- coding: utf-8 -*-
# Copyright (C) 2010, 2011 Rocky Bernstein <rockyb@rubyforge.net>
require 'rubygems'; require 'require_relative'
require_relative '../command'
require_relative '../eval'
class Trepan::Command::MacroCommand < Trepan::Command

  unless defined?(HELP)
    NAME          = File.basename(__FILE__, '.rb')
    HELP = <<-HELP
#{NAME} MACRO-NAME PROC-OBJECT

Define MACRO-NAME as a debugger macro. Debugger macros get a list of
arguments. 

The macro should return either a String or an Array of Strings which
is substituted for the command.  If the return is a String, that gets
tokenized by a simple String#split .  Note that macro processing is
done right after splitting on ;; so if the macro returns a string
containing ;; this will not be handled on the string returned.

If instead, Array of Strings is returned, then the first string is
unshifted from the array and executed. The remaning strings are pushed
onto the command queue. In contrast to the first string, subsequent
strings can contain other macros, and ;; in those strings will be
split into separate commands.

Here is an example. The below creates a macro called finish+ which
issues two commands 'finish' followed by 'step':

  macro fin+ Proc.new{|*args| %w(finish step)}

See also 'info macro'.
    HELP

    CATEGORY      = 'support'
    MIN_ARGS      = 2  # Need at least this many
    SHORT_HELP    = 'Define a macro'
  end
  
  def run(args)
    cmd_name = args[1]
    cmd_argstr = @proc.cmd_argstr[cmd_name.size..-1].lstrip
    proc_obj = @proc.debug_eval(cmd_argstr, @proc.settings[:maxstring])
    if proc_obj
      if proc_obj.is_a?(Proc)
        @proc.macros[cmd_name] = [proc_obj, cmd_argstr]
        msg "Macro \"#{cmd_name}\" defined."
      else
        errmsg "Expecting a Proc object; got: #{cmd_argstr}"
      end
    end
  end
end
        
if __FILE__ == $0
  require_relative '../mock'
  dbgr, cmd = MockDebugger::setup
  cmdproc = cmd.proc
  ["#{cmd.name} foo Proc.new{|x, y| 'x+y'}",
   "#{cmd.name} bad2 1+2"].each do |cmdline|
    args = cmdline.split
    cmd_argstr = cmdline[args[0].size..-1].lstrip
    cmdproc.instance_variable_set('@cmd_argstr', cmd_argstr)
    cmd.run(args)
  end
  p cmdproc.macros
end
