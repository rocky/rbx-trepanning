# -*- coding: utf-8 -*-
# Copyright (C) 2010 Rocky Bernstein <rockyb@rubyforge.net>
require 'rubygems'; require 'require_relative'
require_relative '../base/subcmd'

class Trepan::Subcommand::ShowBasename < Trepan::ShowBoolSubcommand
  unless defined?(HELP)
    HELP       = "Show only file basename in showing file names"
    MIN_ABBREV = 'ba'.size

    # FIXME: DRY setting NAME and PREFIX
    NAME       = File.basename(__FILE__, '.rb')
    dirname    = File.basename(File.dirname(File.expand_path(__FILE__)))
    PREFIX     = %W(#{dirname[0...-'_subcmd'.size]}
                    #{NAME})
  end

end

if __FILE__ == $0
  # Demo it.
  $0 = __FILE__ + 'notagain' # So we don't run this agin
  require_relative '../../mock'
  cmd = MockDebugger::sub_setup(Trepan::Subcommand::ShowBasename, false)
  cmd.run(cmd.prefix)
end
