require 'rubygems'; require 'require_relative'
require_relative './base/cmd'

class Trepan::Command::BacktraceCommand < Trepan::Command
  ALIASES      = %w(bt)
  CATEGORY     = 'stack'
  HELP = <<-HELP
Show the call stack as a simple list.

Passing "-v" will also show the values of all locals variables
in each frame.
      HELP
  NAME         = File.basename(__FILE__, '.rb')
  NEED_STACK   = true
  SHORT_HELP   =  'Show the current call stack'
  
  def run(args)
    arg_str = args[1..-1].join(' ')
    verbose = (arg_str =~ /-v/)
    
    if m = /(\d+)/.match(arg_str)
      count = m[1].to_i
    else
      count = nil
    end
    
    msg "Backtrace:"
    
    @proc.dbgr.each_frame(@proc.frame) do |frame|
      return if count and frame.number >= count
      
      msg "%4d %s" % [frame.number, frame.describe]
      
      if verbose
        frame.local_variables.each do |local|
          msg "       #{local} = #{frame.run(local.to_s).inspect}"
        end
      end
    end
  end
end

