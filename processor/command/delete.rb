require 'rubygems'; require 'require_relative'
require_relative './base/cmd'

class Trepan::Command::DeleteBreakpontCommand < Trepan::Command
  CATEGORY     = 'breakpoints'
  NAME         = File.basename(__FILE__, '.rb')
  SHORT_HELP   = 'Delete a breakpoint'
  HELP         = <<-HELP
Specify the breakpoint by number, use 'info break' to see the numbers
      HELP

  def run(args)
    if args.size != 2
      errmsg 'Please specify which breakpoint by number'
      return
    end
    
    begin
      i = Integer(args[1])
    rescue ArgumentError
      errmsg "'#{args}' is not a number"
      return
    end
    
    if @proc.dbgr.delete_breakpoint_by_number(i)
      msg('Deleted breakpoint %d.' % i)
    end
  end
end

