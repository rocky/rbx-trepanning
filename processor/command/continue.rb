# Copyright (C) 2011 Rocky Bernstein <rockyb@rubyforge.net>
require 'rubygems'; require 'require_relative'
require_relative 'base/cmd'
require_relative '../stepping'

class Trepan::Command::ContinueCommand < Trepan::Command
  unless defined?(HELP)
    NAME = File.basename(__FILE__, '.rb')
    HELP = <<-HELP
#{NAME} [breakpoint-position]

Leave the debugger loop and continue execution. Subsequent entry to
the debugger however may occur via breakpoints or explicit calls, or
exceptions.

If a parameter is given, a temporary breakpoint is set at that position
before continuing. Offset are numbers prefixed with an "O" otherwise
the parameter is taken as a line number.

Examples:
   #{NAME}
   #{NAME} 10    # continue to line 10
   #{NAME} o20   # continue to VM Instruction Sequence offset 20
   #{NAME} gcd   # continue to first instruction of method gcd
   #{NAME} IRB.start o7 # continue to IRB.start offset 7

See also 'step', 'next', 'finish', and 'nexti' commands.
    HELP

    ALIASES      = %w(c cont)
    CATEGORY     = 'running'
    MAX_ARGS     = 2  # Need at most this many
    NEED_RUNNING = true
    SHORT_HELP   = 'Continue execution of the debugged program'
  end

  # This is the method that runs the command
  def run(args)

    ## FIXME: DRY this code, tbreak and break.
    unless args.size == 1
      describe, klass_name, which, name, line, ip = 
        @proc.breakpoint_position(args[1..-1])
      unless describe
        errmsg "Can't parse temporary breakpoint location"
        return 
      end
      if name.kind_of?(Rubinius::CompiledMethod)
        bp = @proc.set_breakpoint_method(describe, name, line, ip,
                                         {:temp=>true, :event =>'tbrkpt'})
        unless bp
          errmsg "Trouble setting temporary breakpoint"
          return 
        end
      else
        return unless klass_name
        begin
          klass = @proc.debug_eval(klass_name, settings[:maxstring])
        rescue NameError
          errmsg "Unable to find class/module: #{klass_name}"
          return
        end
        
        begin
          if which == "#"
            method = klass.instance_method(name)
          else
            method = klass.method(name)
          end
        rescue NameError
          errmsg "Unable to find method '#{name}' in #{klass}"
          return
        end
        arg_str = args[1..-1].join(' ')
        bp = @proc.set_breakpoint_method(arg_str.strip, method, line, nil,
                                         {:temp=>true, :event =>'tbrkpt'})
        unless bp
          errmsg "Trouble setting temporary breakpoint"
          return 
        end
      end
    end
    @proc.continue('continue')
  end
end

if __FILE__ == $0
  require_relative '../mock'
  dbgr, cmd = MockDebugger::setup
  p cmd.run([cmd.name])
end
