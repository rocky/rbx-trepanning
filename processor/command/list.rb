# Copyright (C) 2010, 2011 Rocky Bernstein <rockyb@rubyforge.net>
# -*- coding: utf-8 -*-
require 'rubygems'
require 'require_relative'
require 'linecache'
require_relative 'base/cmd'

class Trepan::Command::ListCommand < Trepan::Command
  unless defined?(HELP)
    NAME = File.basename(__FILE__, '.rb')
    HELP = <<-HELP
#{NAME}[>] [FIRST [NUM]]
#{NAME}[>] LOCATION [NUM]

#{NAME} source code. 

Without arguments, prints lines centered around the current
line. If this is the first #{NAME} command issued since the debugger
command loop was entered, then the current line is the current
frame. If a subsequent #{NAME} command was issued with no intervening
frame changing, then that is start the line after we last one
previously shown.

If the command has a '>' suffix, then line centering is disabled and
listing begins at the specificed location.

The number of lines to show is controlled by the debugger "list size"
setting. Use 'set max list' or 'show max list' to see or set the
value.

\"#{NAME} -\" shows lines before a previous listing. 

A LOCATION is a either 
  - number, e.g. 5, 
  - a function, e.g. join or os.path.join
  - a module, e.g. os or os.path
  - a filename, colon, and a number, e.g. foo.rb:5,  
  - or a module name and a number, e.g,. os.path:5.  
  - a '.' for the current line number
  - a '-' for the lines before the current line number

If the location form is used with a subsequent parameter, the
parameter is the starting line number.  When there two numbers are
given, the last number value is treated as a stopping line unless it
is less than the start line, in which case it is taken to mean the
number of lines to list instead.

Wherever a number is expected, it does not need to be a constant --
just something that evaluates to a positive integer.

Some examples:

#{NAME} 5            # List centered around line 5
#{NAME} 4+1          # Same as above.
#{NAME} 5>           # List starting at line 5
#{NAME} foo.rb:5     # List centered around line 5 of foo.rb
#{NAME} foo.rb 5     # Same as above.
#{NAME} foo.rb:5>    # List starting around line 5 of foo.rb
#{NAME} foo.rb  5 6  # list lines 5 and 6 of foo.rb
#{NAME} foo.rb  5 2  # Same as above, since 2 < 5.
#{NAME} foo.rb:5 2   # Same as above
#{NAME} FileUtils.cp # List lines around the FileUtils.cp function.
#{NAME} .            # List lines centered from where we currently are stopped
#{NAME} . 3          # List 3 lines starting from where we currently are stopped
                     # if . > 3. Otherwise we list from . to 3.
#{NAME} -            # List lines previous to those just shown

    HELP

    ALIASES       = %W(l #{NAME}> l>)
    CATEGORY      = 'files'
    MAX_ARGS      = 3
    SHORT_HELP    = 'List source code'
  end

  # If last is less than first, assume last is a count rather than an
  # end line number.
  def adjust_last(first, last)
    last < first ? first + last - 1 : last
  end

  # What a f*cking mess. Necessitated I suppose because we want to 
  # allow somewhat flexible parsing with either module names, files or none
  # and optional line counts or end-line numbers.
  
  # Parses arguments for the "list" command and returns the tuple:
  # filename, start, last
  # or sets these to nil if there was some problem.
  def parse_list_cmd(args, listsize, center_correction)
    
    last = nil
    
    if args.size > 0
      if args[0] == '-'
        return no_frame_msg unless @proc.line_no
        first = [1, @proc.line_no - 2*listsize - 1].max
        file  = @proc.frame.file
      elsif args[0] == '.'
        return no_frame_msg unless @proc.line_no
        if args.size == 2
          opts = {
            :msg_on_error => 
            "#{NAME} command last or count parameter expected, " +
            'got: %s.' % args[2]
          }
          second = @proc.get_an_int(args[1], opts)
          return nil, nil, nil unless second
          first = @proc.frame.line 
          last = adjust_last(first, second)
        else
          first = [1, @proc.frame.line - center_correction].max
        end

        file  = @proc.frame.file
      else
        modfunc, file, first = @proc.parse_position(args[0])
        if first == nil and modfunc == nil
          # error should have been shown previously
          return nil, nil, nil
        end
        if args.size == 1
          first = 1 if !first and modfunc
          first = [1, first - center_correction].max
        elsif args.size == 2 or (args.size == 3 and modfunc)
          opts = {
            :msg_on_error => 
            "#{NAME} command starting line expected, got %s." % args[-1]
          }
          last = @proc.get_an_int(args[1], opts)
          return nil, nil, nil unless last
          if modfunc
            if first
              first = last
              if args.size == 3 and modfunc
                opts[:msg_on_error] = 
                  ("#{NAME} command last or count parameter expected, " +
                   'got: %s.' % args[2])
                last = @proc.get_an_int(args[2], opts)
                return nil, nil, nil unless last
              end
            end
          end
          last = adjust_last(first, last)
        elsif not modfunc
          errmsg('At most 2 parameters allowed when no module' +
                  ' name is found/given. Saw: %d parameters' % args.size)
          return nil, nil, nil
        else
          errmsg(('At most 3 parameters allowed when a module' +
                  ' name is given. Saw: %d parameters') % args.size)
          return nil, nil, nil
        end
      end
    elsif !@proc.line_no and @proc.frame
      first = [1, @proc.frame.line - center_correction].max
      file  = @proc.frame.file
    else
      first = [1, @proc.line_no - center_correction].max 
      file  = @proc.frame.file
    end
    last = first + listsize - 1 unless last

    if @proc.frame.eval?
      script = @proc.frame.vm_location.static_scope.script 
      LineCache::cache(script)
    else
      LineCache::cache(file)
      script = nil
    end
    return file, script, first, last
  end

  def no_frame_msg
    errmsg("No Ruby program loaded.")
    return nil, nil, nil
  end
    
  def run(args)
    listsize = settings[:maxlist]
    center_correction = 
      if args[0][-1..-1] == '>'
        0
      else
        (listsize-1) / 2
      end

    file, script, first, last = 
      parse_list_cmd(args[1..-1], listsize, center_correction)
    frame = @proc.frame
    return unless file

    cached_item = script || file

    # We now have range information. Do the listing.
    max_line = LineCache::size(cached_item)

    # FIXME: join with line_at of location.rb
    unless max_line && file
      # Try using search directories (set with command "directory")
      if file[0..0] != File::SEPARATOR
        try_filename = @proc.resolve_file_with_dir(file) 
        if try_filename && 
            max_line = LineCache::size(try_filename)
          LineCache::remap_file(file, try_filename)
        end
      end
    end

    unless max_line 
      errmsg('File "%s" not found.' % file)
      return
    end

    if first > max_line
      errmsg('Bad line range [%d...%d]; file "%s" has only %d lines' %
             [first, last, file, max_line])
      return
    end

    if last > max_line
      # msg('End position changed to last line %d ' % max_line)
      last = max_line
    end

    begin
      opts = {
        :reload_on_change => @proc.reload_on_change,
        :output => settings[:terminal]
      }
      first.upto(last).each do |lineno|
        line = LineCache::getline(cached_item, lineno, opts)
        unless line
          msg('[EOF]')
          break
        end
        line.chomp!
        s = '%3d' % lineno
        s = s + ' ' if s.size < 4 
        s += (@proc.frame && lineno == @proc.frame.vm_location.line) ? '->' : '  '
        # && container == frame.source_container) 
        msg(s + "\t" + line)
        @proc.line_no = lineno
      end
    rescue => e
      errmsg e.to_s if settings[:debugexcept]
    end
  end
end

if __FILE__ == $0
  require_relative '../location'
  require_relative '../mock'
  require_relative '../frame'
  dbgr, cmd = MockDebugger::setup
  cmd.proc.send('frame_initialize')
  LineCache::cache(__FILE__)
  require 'trepanning'
  cmd.run([cmd.name])
  cmd.run([cmd.name, __FILE__ + ':10'])
  
  def run_cmd(cmd, args)
    seps = '--' * 10
    puts "%s %s %s" % [seps, args.join(' '), seps]
    cmd.run(args)
  end
  
  
  load 'tmpdir.rb'
  run_cmd(cmd, %W(#{cmd.name} tmpdir.rb 10))
  run_cmd(cmd, %W(#{cmd.name} tmpdir.rb))
  
  run_cmd(cmd, %W(cmd.name .))
  run_cmd(cmd, %W(cmd.name 30))
  
  # cmd.run(['list', '9+1'])
  
  run_cmd(cmd, %W(cmd.name> 10))
  run_cmd(cmd, %W(cmd.name 3000))
  run_cmd(cmd, %W(cmd.name run_cmd))
  
  p = Proc.new do 
    |x,y| x + y
  end
  run_cmd(cmd, %W(#{cmd.name} p))
  
  # Function from a file found via an instruction sequence
  run_cmd(cmd, %W(#{cmd.name} Columnize.columnize))
  
  # Use Class/method name. 15 isn't in the function - should this be okay?
  run_cmd(cmd, %W(#{cmd.name} Columnize.columnize 15))
  
  # Start line and count, since 3 < 30
  run_cmd(cmd, %W(#{cmd.name} Columnize.columnize 30 3))
  
  # Start line finish line 
  run_cmd(cmd, %W(#{cmd.name} Columnize.columnize 40 50))

  # Method name
  run_cmd(cmd, %W(#{cmd.name} cmd.run))
end
