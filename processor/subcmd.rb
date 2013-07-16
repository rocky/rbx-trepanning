# Copyright (C) 2010, 2011 Rocky Bernstein <rockyb@rubyforge.net>
# gdb-like subcommand processing.

### FIXME: move into command/base/submgr.rb
class Trepan
  class Subcmd

    attr_reader :subcmds  # Hash of subcommands. Key is the subcommand name.
                          # the value is the subcommand object to run.
    def initialize(cmd)
      @cmd     = cmd
      @subcmds = {}
      @cmdlist = []
    end

    # Find subcmd in self.subcmds
    def lookup(subcmd_prefix, use_regexp=true)
      compare =
        if !@cmd.settings[:abbrev]
          lambda{|name| name.to_s == subcmd_prefix}
        elsif use_regexp
          lambda{|name| name.to_s =~ /^#{subcmd_prefix}/}
        else
          lambda{|name| 0 == name.to_s.index(subcmd_prefix)}
        end
      candidates = []
      @subcmds.each do |subcmd_name, subcmd|
        if compare.call(subcmd_name) &&
            subcmd_prefix.size >= subcmd.class.const_get(:MIN_ABBREV)
          candidates << subcmd
        end
      end
      if candidates.size == 1
        return candidates.first
      end
      return nil
    end

    # Show short help for a subcommand.
    def short_help(subcmd_cb, subcmd_name, label=false)
      entry = self.lookup(subcmd_name)
      if entry
        if label
          prefix = entry.name
        else
          prefix = ''
        end
        if entry.respond_to?(:short_help)
          prefix += ' -- ' if prefix
          @proc.msg(prefix + entry.short_help)
        end
      else
        @proc.undefined_subcmd("help", subcmd_name)
      end
    end

    # Add subcmd to the available subcommands for this object.
    # It will have the supplied docstring, and subcmd_cb will be called
    # when we want to run the command. min_len is the minimum length
    # allowed to abbreviate the command. in_list indicates with the
    # show command will be run when giving a list of all sub commands
    # of this object. Some commands have long output like "show commands"
    # so we might not want to show that.
    def add(subcmd_cb, subcmd_name=nil)
      subcmd_name ||= subcmd_cb.name
      @subcmds[subcmd_name] = subcmd_cb

      # We keep a list of subcommands to assist command completion
      @cmdlist << subcmd_name
    end

    # help for subcommands
    # Note: format of help is compatible with ddd.
    def help(*args)
      # Not used but tested for.
    end

    def list
      @subcmds.keys.map{|k| k.to_s}.sort
    end
  end
end

# When invoked as main program, invoke the debugger on a script
if __FILE__ == $0

  require 'rubygems'; require 'require_relative'
  require_relative 'mock'
  require_relative 'command'

  class Trepan::TestCommand < Trepan::Command

    HELP = 'Help string string for testing'
    CATEGORY = 'data'
    MIN_ARGS = 0
    MAX_ARGS = 5
    NAME_ALIASES = %w(test)

    def initialize(proc); @proc  = proc end

    def run(args); puts 'test command run' end
  end

  class TestTestingSubcommand
    HELP = 'Help string for test testing subcommand'

    def initialize; @name  = 'testing' end

    SHORT_HELP = 'This is short help for test testing'
    MIN_ABREV = 4
    IN_LIST   = true
    def run(args); puts 'test testing run' end
  end

  d = MockDebugger::MockDebugger.new
  testcmd    = Trepan::TestCommand.new(nil)
  # testcmd.debugger = d
  # testcmd.proc     = d.core.processor
  # testcmdMgr = Subcmd.new('test', testcmd)
  # testsub = TestTestingSubcommand.new
  # testcmdMgr.add(testsub)

  # %w(tes test testing testing1).each do |prefix|
  #   x = testcmdMgr.lookup(prefix)
  #   puts x ? x.name : 'Non'
  # end

  # testcmdMgr.short_help(testcmd, 'testing')
  # testcmdMgr.short_help(testcmd, 'test', true)
  # testcmdMgr.short_help(testcmd, 'tes')
  # puts testcmdMgr.list()
  # testsub2 = TestTestingSubcommand.new
  # testsub2.name = 'foobar'
  # testcmdMgr.add(testsub2)
  # puts testcmdMgr.list()
end
