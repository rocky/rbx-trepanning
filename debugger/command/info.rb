require 'rubygems'; require 'require_relative'
require_relative './base/cmd'

class RBDebug::Command::ShowInfo < RBDebug::Command
  pattern "i", "info"
  help "Show information about things"
  ext_help <<-HELP
Subcommands are:
  break, breakpoints, bp: List all breakpoints
      HELP
  
  def run(args)
    case args.strip
    when "break", "breakpoints", "bp"
      section "Breakpoints"
      if @debugger.breakpoints.empty?
        info "No breakpoints set"
      end
      
      @debugger.breakpoints.each_with_index do |bp, i|
        if bp
          info "%3d: %s" % [i+1, bp.describe]
        end
      end
    else
      error "Unknown info: '#{args}'"
    end
  end
end

