# -*- coding: utf-8 -*-
# Copyright (C) 2010, 2011 Rocky Bernstein <rockyb@rubyforge.net>
require 'rubygems'; require 'require_relative'
require 'columnize'
require_relative '../../base/subsubcmd'
require_relative '../../../../app/frame'
require_relative '../../../../app/util'

class Trepan::Subcommand::InfoVariablesLocals < Trepan::SubSubcommand
  Trepan::Util.suppress_warnings {
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
  }

  def get_names
    @proc.frame.local_variables
  end

  def run_for_type(args, type, klass=nil)
    suffix = klass ? " for #{klass.to_s}" : '' rescue ''
    names = get_names()
    if args.size == 2
      if 0 == 'names'.index(args[-1].downcase)
        names = get_names()
        if names.empty?
          msg "No #{type} variables defined."
        else
          section "#{type.capitalize} variable names#{suffix}:"

          width = settings[:maxwidth]
          mess = Columnize::columnize(names, 
                                      @proc.settings[:maxwidth], '  ',
                                      false, true, ' ' * 2).chomp
          msg mess
        end
      else
        errmsg("unrecognized argument: #{args[-1]}")
      end
    elsif args.size == 1
      if names.empty?
        msg "No #{type} variables defined#{suffix}."
      else
        section "#{type.capitalize} variables#{suffix}:"
        names.each do |var_name| 
          var_value = 
            @proc.safe_rep(@proc.debug_eval_no_errmsg(var_name).inspect)
          msg("#{var_name} = #{var_value}", :code =>true)
        end
      end
    else
      errmsg("Wrong number of arguments #{args.size}")
    end
  end
  def run(args)
    run_for_type(args, 'local', @proc.debug_eval('self'))
  end
end

if __FILE__ == $0
  # Demo it.
  require_relative '../../../mock'
  require_relative '../variables'
  cmd = MockDebugger::subsub_setup(Trepan::SubSubcommand::InfoVariables,
                                   Trepan::SubSubcommand::InfoVariablesLocals
                                   )
  cmd.run([])
  cmd.run(['name'])
end
