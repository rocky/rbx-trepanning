# -*- coding: utf-8 -*-
# Copyright (C) 2010 Rocky Bernstein <rockyb@rubyforge.net>
require 'rubygems'; require 'require_relative'
require_relative '../base/subcmd'

class Trepan::Subcommand::InfoMethod < Trepan::Subcommand
  unless defined?(HELP)
    HELP         = 
'info [METHOD|.]

Show information about a method.

Examples:
  info method
  info method .
  info method require_relative
'
    MIN_ABBREV   = 'me'.size
    NAME         = File.basename(__FILE__, '.rb')
    NEED_STACK   = true
    PREFIX       = %w(info method)
    SHORT_HELP   = 'Information about a (compiled) method'
  end

  def run(args)
    if args.size <= 2
      method_name = '.'
    else
      method_name = args[2]
    end
    if '.' == method_name
      meth = @proc.frame.method
    # elsif ...
    #   # FIXME: do something if there is more than one
    else
      meth = nil
    end
    
    if meth
      msg("Method #{meth.name}():")
      %w(arity         child_methods describe
         file          first_line    lines         local_count
         required_args splat         stack_size    total_args 
         ).each do |field|
        msg "  %-15s: %s" % [field, meth.send(field).inspect]
      end
    else
      mess = "Can't find method"
      mess += " for #{args.join(' ')}" unless args.empty?
      errmsg mess
    end
  end

end

if __FILE__ == $0
  # Demo it.

  require_relative '../../mock'
  require_relative '../../subcmd'
  name = File.basename(__FILE__, '.rb')

  # FIXME: DRY the below code
  dbgr, cmd = MockDebugger::setup('info')
  subcommand = Trepan::Subcommand::InfoMethod.new(cmd)
  testcmdMgr = Trepan::Subcmd.new(subcommand)

  subcommand.run([name])
  name = File.basename(__FILE__, '.rb')
  subcommand.summary_help(name)
end
