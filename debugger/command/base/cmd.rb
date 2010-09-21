require File.expand_path(File.dirname(__FILE__)) + '/../../display'

class RBDebug
  class CommandDescription
    attr_accessor :klass, :patterns, :help, :ext_help

    def initialize(klass)
      @klass = klass
    end

    def name
      @klass.name
    end
  end

  class Command
    attr_reader :commands
    include RBDebug::Display

    @commands = []

    def self.commands
      @commands
    end

    def self.commands=(value)
      @commands=value
    end

    def self.descriptor
      @descriptor ||= CommandDescription.new(self)
    end

    def self.pattern(*strs)
      # FIXME: until we rewrite so as to not to
      # do a runner.new which causes us to keep adding
      # to commands we need the "unless"
      unless Command.commands.member?(self)
        Command.commands << self 
        descriptor.patterns = strs
      end
    end

    def self.help(str)
      descriptor.help = str
    end

    def self.ext_help(str)
      descriptor.ext_help = str
    end

    def self.match?(cmd)
      descriptor.patterns.include?(cmd)
    end

    def initialize(debugger)
      @debugger = debugger

      # FIXME: The following causes singleton @commands to grow and
      # grow... Revise...
      cmd_dirs = [ File.join(File.dirname(__FILE__), '..') ]
      cmd_dirs.each do |cmd_dir| 
        load_debugger_commands(cmd_dir) if File.directory?(cmd_dir)
      end 
    end

    def load_debugger_commands(cmd_dir)
      Dir.glob(File.join(cmd_dir, '*.rb')).each do |rb| 
        require rb
      end if File.directory?(cmd_dir)
    end


    def run_code(str)
      @debugger.current_frame.run(str)
    end

    def current_method
      @debugger.current_frame.method
    end

    def current_frame
      @debugger.current_frame
    end

    def variables
      @debugger.variables
    end

    def listen(step=false)
      @debugger.listen(step)
    end
  end
end
