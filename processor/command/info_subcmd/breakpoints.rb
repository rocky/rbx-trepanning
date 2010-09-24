require 'rubygems'; require 'require_relative'
require_relative '../base/subcmd'

class Trepan::Subcommand::InfoBreakpoints < Trepan::Subcommand
  MIN_ABBREV   = 'br'.size
  NAME         = File.basename(__FILE__, '.rb')
  PREFIX       = %w(info breakpoints)
  SHORT_HELP   = 'Status of user-settable breakpoints'
  
  def run(args)
    # FIXME: Originally was 
    #   section "Breakpoints"
    # Add section? 
    msg 'Breakpoints'
    if @proc.dbgr.breakpoints.empty?
      msg 'No breakpoints.'
    end
    
    @proc.dbgr.breakpoints.each_with_index do |bp, i|
      if bp
        msg "%3d: %s" % [i+1, bp.describe]
      end
    end
  end
end

if __FILE__ == $0
  # Demo it.
  require_relative '../../mock'
  name = File.basename(__FILE__, '.rb')
  dbgr, cmd = MockDebugger::setup('info')
  subcommand = Trepan::Subcommand::InfoBreakpoints.new(cmd)

  # puts '-' * 20
  # subcommand.run(%w(info break))
  puts '-' * 20
  subcommand.summary_help(name)
  puts
  puts '-' * 20
end
