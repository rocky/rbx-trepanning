# -*- coding: utf-8 -*-
# Copyright (C) 2010, 2011 Rocky Bernstein <rockyb@rubyforge.net>
require 'rubygems'; require 'require_relative'
require 'columnize'
require_relative '../base/subcmd'
require_relative '../../../app/frame'

class Trepan::Subcommand::InfoLocals < Trepan::Subcommand
  unless defined?(HELP)
    Trepanning::Subcommand.set_name_prefix(__FILE__, self)
    HELP         = <<-EOH
#{CMD}
#{CMD} [names]

Show local variables including parameters of the current stack frame.
Normally for each which show both the name and value. If you just
want a list of names add parameter 'names'.
EOH
    SHORT_HELP   = 'Show local variables of the current stack frame'
    MIN_ARGS     = 0
    MAX_ARGS     = 1
    MIN_ABBREV   = 'lo'.size 
    NEED_STACK   = true
  end

  def get_local_names
    @proc.frame.local_variables
  end

  def run(args)
    if args.size == 3
      if 0 == 'names'.index(args[-1].downcase)
        local_names = get_local_names()
        if local_names.empty?
            msg "No local variables defined."
        else
          section "Local variable names:"
          width = settings[:maxwidth]
          mess = Columnize::columnize(local_names, 
                                      @proc.settings[:maxwidth], ', ',
                                      false, true, ' ' * 2).chomp
          msg mess
        end
      else
        errmsg("unrecognized argument #{args[2]}")
      end
    elsif args.size == 2
      local_names = get_local_names
      if local_names.empty?
        msg "No local variables defined."
      else
        section "Local variables:"
        local_names.each do |var_name| 
          msg("#{var_name} = %s" %
              @proc.debug_eval("#{var_name}.inspect"))
        end
      end
    else
      errmsg("Wrong number of arguments #{args.size}")
    end
  end
end

if __FILE__ == $0
  # Demo it.
  require_relative '../../mock'
  cmd = MockDebugger::sub_setup(Trepan::Subcommand::InfoLocals, false)
  cmd.run(cmd.prefix)
  cmd.run(cmd.prefix + ['name'])
end
