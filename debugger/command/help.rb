require 'rubygems'; require 'require_relative'
require_relative './base/cmd'

class RBDebug::Help < RBDebug::Command
  pattern "help"
  help "Show information about debugger commands"
  
  def run(args)
    
    if args and !args.empty?
      klass = RBDebug::Command.commands.find { |k| k.match?(args.strip) }
      if klass
        des = klass.descriptor
        info "Help for #{des.name}:"
        info "  Accessed using: #{des.patterns.join(', ')}"
        info "\n#{des.help}."
        info "\n#{des.ext_help}" if des.ext_help
      else
        error "Unknown command: #{args}"
      end
    else
      RBDebug::Command.commands.each do |klass|
        des = klass.descriptor
        
        info "%20s: #{des.help}" % des.patterns.join(', ')
      end
    end
  end
end


