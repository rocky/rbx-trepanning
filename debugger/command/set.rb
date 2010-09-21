require 'rubygems'; require 'require_relative'
require_relative './base/cmd'

class RBDebug::Command::SetVariable < RBDebug::Command
  pattern "set"
  help "Set a debugger config variable"
  ext_help <<-HELP
Set a debugger configuration variable. Use 'show' to see all variables.
      HELP
  
  def run(args)
    var, val = args.split(/\s+/, 2)
    
    if val
      case val.strip
      when "true", "on", "yes", ""
        val = true
      when "false", "off", "no"
        val = false
      when "nil"
        val = nil
      when /\d+/
        val = val.to_i
      end
    else
      val = true
    end
    
    info "Set '#{var}' = #{val.inspect}"
    
    @debugger.variables[var.to_sym] = val
  end
end

