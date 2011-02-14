# -*- coding: utf-8 -*-
# Copyright (C) 2010, 2011 Rocky Bernstein <rockyb@rubyforge.net>
require 'rubygems'; require 'require_relative'
require_relative 'base/cmd'
require_relative '../eval'
class Trepan::Command::MacroCommand < Trepan::Command

  unless defined?(HELP)
    NAME          = File.basename(__FILE__, '.rb')
    HELP = <<-HELP
#{NAME} MACRO-NAME PROC-OBJECT

Define MACRO-NAME as a debugger macro. Debugger macros get a list of
arguments and should return either a String or an Array of Strings to
use in its place.  If the return is a String, that gets tokenized by a
simple String#split .  Note that macro processing is done right after
splitting on ;; so if the macro returns a string containing ;; those
won't be handled on the first string returned.

If instead, Array of Strings is returned, then the first string is
unshifted from the array and executed. The remaning strings are pushed
onto the command queue. In contrast to the first string, subsequent
strings which contain other macros or ;; splitting will be acted upon.

Here is an example. The below creates a macro called finish+ which
issues two commands 'finish' followed by 'step':

  macro finish+ Proc.new{|*args| ['finish', 'step']}

Here is another example using arguments. I use the following to debug
a debugger command:

  macro dbgcmd Proc.new{|*args| ["set debug dbgr", "debug $trepan_cmdproc.commands['\#{args[0]}'].run(\#{args.inspect})"]}

With the above, 'dbgcmd list 5' will ultimately expand to: 
  set debug dbgr
  debug $trepan_cmdproc.commands['list'].run(['5'])

and will debug the debugger's 'list' command on the command 'list 5'.

See also 'show macro'.
    HELP

    CATEGORY      = 'support'
    MIN_ARGS      = 2  # Need at least this many
    SHORT_HELP    = 'Define a macro'
  end
  
  def run(args)
    macro_name = args[1]
    proc_argstr = @proc.cmd_argstr[macro_name.size..-1].lstrip
    proc_obj = @proc.debug_eval(proc_argstr, @proc.settings[:maxstring])
    if proc_obj
      if proc_obj.is_a?(Proc)
        @proc.macros[macro_name] = proc_obj
        msg "Macro \"#{macro_name}\" defined."
      else
        errmsg "Expecting a Proc object; got: #{proc_argstr}"
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
