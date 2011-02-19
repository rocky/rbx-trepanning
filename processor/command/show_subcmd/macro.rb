# -*- coding: utf-8 -*-
# Copyright (C) 2010, 2011 Rocky Bernstein <rockyb@rubyforge.net>
require 'rubygems'; require 'require_relative'
require_relative '../base/subcmd'
require_relative '../../../app/complete'

class Trepan::Subcommand::ShowMacro < Trepan::Subcommand
  unless defined?(HELP)
    Trepanning::Subcommand.set_name_prefix(__FILE__, self)
    HELP = "Show defined macros"
    MIN_ABBREV = 'ma'.size
  end

  def complete(prefix)
    Trepan::Complete.complete_token(@proc.macros.keys, prefix)
  end

  def run(args)
    if args.size > 2
      args[2..-1].each do |macro_name|
        if @proc.macros.member?(macro_name)
          section "#{macro_name}:"
          string = @proc.macros[macro_name][1]
          msg "  #{@proc.ruby_format(string)}"
        else
          errmsg "%s is not a defined macro" % macro_name
        end
      end
    elsif @proc.macros.empty?
      msg "No macros defined."
    else
      msg columnize_commands(@proc.macros.keys.sort)
    end
  end

end

if __FILE__ == $0
  # Demo it.
  $0 = __FILE__ + 'notagain' # So we don't run this agin
  require_relative '../../mock'
  cmd = MockDebugger::sub_setup(Trepan::Subcommand::ShowMacro)
  cmd.run(cmd.prefix + %w(u foo))
end
