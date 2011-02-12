# -*- coding: utf-8 -*-
# Copyright (C) 2010, 2011 Rocky Bernstein <rockyb@rubyforge.net>
require 'rubygems'; require 'require_relative'
require 'linecache'
require 'columnize'
require_relative '../base/subcmd'
require_relative '../../../app/complete'

class Trepan::Subcommand::InfoFiles < Trepan::Subcommand
  unless defined?(HELP)
    Trepanning::Subcommand.set_name_prefix(__FILE__, self)
    DEFAULT_FILE_ARGS = %w(size mtime sha1)

    HELP = <<-EOH
#{CMD=PREFIX.join(' ')} [{FILENAME|.|*} [all|ctime|brkpts|mtime|sha1|size|stat]]

Show information about the current file. If no filename is given and
the program is running, then the current file associated with the
current stack entry is used. Giving . has the same effect. 

Given * gives a list of all files we know about.

Sub options which can be shown about a file are:

brkpts -- Line numbers where there are statement boundaries. 
          These lines can be used in breakpoint commands.
ctime  -- File creation time
mtime  -- File modification time
sha1   -- A SHA1 hash of the source text. This may be useful in comparing
          source code.
size   -- The number of lines in the file.
stat   -- File.stat information

all    -- All of the above information.

If no sub-options are given, "#{DEFAULT_FILE_ARGS.join(' ')}" are assumed.

Examples:

#{CMD}    # Show #{DEFAULT_FILE_ARGS.join(' ')} information about current file
#{CMD} .  # same as above
#{CMD} brkpts      # show the number of lines in the current file
#{CMD} brkpts size # same as above but also list breakpoint line numbers
#{CMD} *  # Give a list of files we know about
EOH
    MIN_ABBREV   = 'fi'.size  # Note we have "info frame"
    NEED_STACK   = false
  end

  # completion %w(all brkpts iseq sha1 size stat)

  include Trepanning

  def file_list
    (LineCache.class_variable_get('@@file_cache').keys +
     LineCache.class_variable_get('@@file2file_remap').keys).uniq
  end
  def complete(prefix)
    completions = ['.'] + file_list
    Trepan::Complete.complete_token(completions, prefix)
  end
  
  # Get file information
  def run(args)
    return if args.size < 2
    args << '.' if 2 == args.size 
    if '*' == args[2]
      section 'Files names cached:'
      msg columnize_commands(file_list.sort)
      return
    end
    filename = 
      if '.' == args[2]
        if not @proc.frame
          errmsg("No frame - no default file.")
          return false
          nil
        else
          File.expand_path(@proc.frame.file)
        end
      else
        args[2]
      end
    args += DEFAULT_FILE_ARGS if args.size == 3

    m = filename + ' is'
    canonic_name = LineCache::map_file(filename) || filename
    if LineCache::cached?(canonic_name)
      m += " cached in debugger"
      if canonic_name != filename
        m += (' as:' + canonic_name)
      end
      m += '.'
      msg(m)
    # elsif !(matches = find_scripts(filename)).empty?
    #   if (matches.size > 1)
    #     msg("Multiple files found:")
    #     matches.each { |filename| msg("\t%s" % filename) }
    #     return
    #   else
    #     msg('File "%s" just now cached.' % filename)
    #     LineCache::cache(matches[0])
    #     LineCache::remap_file(matches[0], filename)
    #     canonic_name = matches[0]
    #   end
    else
      matches = file_list.select{|try| try.end_with?(filename)}
      if (matches.size > 1)
        msg("Multiple files found ending filename string:")
        matches.sort.each { |match_file| msg "\t%s" % match_file }
        return
      elsif 1 == matches.size
        canonic_name = LineCache::map_file(matches[1])
      else
        msg(m + ' not cached in debugger.')
        return
      end
    end
    seen = {}
    args[3..-1].each do |arg|
      processed_arg = false

      if %w(all size).member?(arg) 
        unless seen[:size]
          max_line = LineCache::size(canonic_name)
          msg "File has %d lines." % max_line if max_line
        end
        processed_arg = seen[:size] = true
      end

      if %w(all sha1).member?(arg)
        unless seen[:sha1]
          msg("SHA1 is %s." % LineCache::sha1(canonic_name))
        end
        processed_arg = seen[:sha1] = true
      end

      if %w(all brkpts).member?(arg)
        unless seen[:brkpts]
          msg("Possible breakpoint line numbers:")
          lines = LineCache::trace_line_numbers(canonic_name)
          fmt_lines = columnize_numbers(lines)
          msg(fmt_lines)
        end
        processed_arg = seen[:brkpts] = true
      end

      if %w(all ctime).member?(arg)
        unless seen[:ctime]
          msg("create time:\t%s." % 
              LineCache::stat(canonic_name).ctime.to_s)
        end
        processed_arg = seen[:ctime] = true
      end
      
      # if %w(all iseq).member?(arg) 
      #   unless seen[:iseq]
      #     if SCRIPT_ISEQS__.member?(canonic_name)
      #       msg("File contains instruction sequences:")
      #       SCRIPT_ISEQS__[canonic_name].each do |iseq|
      #         msg("\t %s %s" % [iseq, iseq.name.inspect])
      #       end 
      #     else
      #       msg("Instruction sequences not recorded; there may be some, though.")
      #     end
      #   end
      #   processed_arg = seen[:iseq] = true
      # end

      if %w(all mtime).member?(arg)
        unless seen[:mtime]
          msg("modify time:\t%s." % 
              LineCache::stat(canonic_name).mtime.to_s)
        end
        processed_arg = seen[:mtime] = true
      end
      
      if %w(all stat).member?(arg)
        unless seen[:stat]
          msg("Stat info:\n\t%s." % LineCache::stat(canonic_name).inspect)
        end
        processed_arg = seen[:stat] = true
      end

      if not processed_arg
        errmsg("I don't understand sub-option \"%s\"." % arg)
      end
    end unless args.empty?
  end
end

if __FILE__ == $0
  require_relative '../../mock'
  cmd = MockDebugger::sub_setup(Trepan::Subcommand::InfoFiles, false)
  LineCache::cache(__FILE__)
  LineCache::cache('../../mock.rb')
  
  [%w(info file nothere),
   %w(info file .),
   %w(info file *),
   %w(info file),
   %W(info file #{__FILE__}),
   %W(info file #{__FILE__} all),
   %W(info file #{__FILE__} brkpts bad size sha1 sha1)].each do |args|
    cmd.run(args)
    puts '-' * 40
  end
  p cmd.complete('')
end
