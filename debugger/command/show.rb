require 'rubygems'; require 'require_relative'
require_relative './base/cmd'

class RBDebug::Command::Show < RBDebug::Command
  pattern "show"
  help "Display the value of a variable or variables"
  ext_help <<-HELP
Show debugger variables and user created variables. By default,
shows all variables.

The optional argument is which variable specificly to show the value of.
      HELP
  
  def run(args)
    if !args or args.strip.empty?
      variables.each do |name, val|
        info "var '#{name}' = #{val.inspect}"
      end
      
      if @debugger.user_variables > 0
        section "User variables"
        (0...@debugger.user_variables).each do |i|
          str = "$d#{i}"
          val = Rubinius::Globals[str.to_sym]
          info "var #{str} = #{val.inspect}"
        end
      end
    else
      var = args.strip.to_sym
      if variables.key?(var)
        info "var '#{var}' = #{variables[var].inspect}"
      else
        error "No variable set named '#{var}'"
      end
    end
    
  end
end
