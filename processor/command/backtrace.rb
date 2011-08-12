# Copyright (C) 2010, 2011 Rocky Bernstein <rockyb@rubyforge.net>
require 'rubygems'; require 'require_relative'
require_relative '../command'

class Trepan::Command::BacktraceCommand < Trepan::Command
  ALIASES      = %w(bt where)
  CATEGORY     = 'stack'
  MAX_ARGS     = 2 # Need at most this many
  NAME         = File.basename(__FILE__, '.rb')
  HELP = <<-HELP
#{NAME} [full] [COUNT]

Print a backtrace of all stack frames, or innermost COUNT frames.  Use
of the 'full' qualifier also prints the values of the local variables.

Passing "full" will also show the values of all locals variables in
each frame.

Normally outer frames which constitute debugger overhead are hidden
from view. However if a count is given and it runs into those hidden
frames, they will be shown.

Examples:

#{NAME}  
#{NAME} full   # show 
#{NAME} 2 
#{NAME} 3 full  
#{NAME} full 3 # same as above
#{NAME} 1000   # probably will show any outer hidden frames

See also 'set hidelevel'.
      HELP
  NEED_STACK   = true
  SHORT_HELP   =  'Show the current call stack'
  
  def complete(prefix)
    @proc.frame_complete(prefix, nil)
  end
  
  # This method runs the command
  def run(args)
    verbose_ary, count_ary = args[1..-1].partition {|item| item =~ /full/i}
    verbose = !verbose_ary.empty?

    if count_ary.size > 1
      errmsg "Expecting only at most one parameter other than 'full'"
      return
    end
    
    if 1 == count_ary.size
      begin
        count = Integer(count_ary[0])
      rescue
        errmsg "Expecting count to be an integer; got #{count_ary[0]}"
        return
      end
    elsif 0 == count_ary.size
      count = proc.stack_size
    else
      errmsg "Wrong number of parameters. Expecting at most 2."
      return
    end
    
    @proc.dbgr.each_frame(@proc.top_frame) do |frame|
      if count and frame.number >= count
        msg "(More stack frames follow...)" if count != proc.stack_size
        return 
      end

      prefix = (frame == @proc.frame) ? '-->' : '   '
      msg "%s #%d %s" % [prefix, frame.number, 
                         frame.describe(:show_ip => verbose)]
      
      if verbose
        frame.local_variables.each do |local|
          msg "       #{local} = #{frame.run(local.to_s).inspect}"
        end
      end
    end
  end
end
