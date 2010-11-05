# Copyright (C) 2010 Rocky Bernstein <rockyb@rubyforge.net>
require 'rubygems'
require 'linecache'
require_relative 'disassemble'
require_relative 'msg'
require_relative 'frame'
class Trepan
  class CmdProcessor
    attr_accessor :reload_on_change

    def location_initialize
      @reload_on_change = nil
    end

    def resolve_file_with_dir(path_suffix)
      settings[:directory].split(/:/).each do |dir|
        dir = 
          if '$cwd' == dir
            Dir.pwd
          elsif '$cdir' == dir
            @dbgr.initial_dir
          else
            dir
          end
        next unless dir && File.directory?(dir)
        try_file = File.join(dir, path_suffix)
        return try_file if File.readable?(try_file)
      end
      nil
    end

    # Get line +line_number+ from file named +filename+. Return "\n"
    # there was a problem. Leading blanks are stripped off.
    def line_at(filename, line_number)
      # We use linecache first to give precidence to user-remapped
      # file names
      line = LineCache::getline(filename, line_number, @reload_on_change)
      unless line
        # Try using search directories (set with command "directory")
        if filename[0..0] != File::SEPARATOR
          try_filename = resolve_file_with_dir(filename) 
          if try_filename && 
              line = LineCache::getline(try_filename, line_number, 
                                        @reload_on_change)
            LineCache::remap_file(filename, try_filename)
          end
        end
      end
      return nil unless line
      return line.lstrip.chomp
    end

    def loc_and_text(loc)
      filename = @frame.location.method.active_path
      line_no  = @frame.location.line
      text     = line_at(filename, line_no)
      map_file, map_line = LineCache::map_file_line(filename, line_no)
      if [filename, line_no] != [map_file, map_line]
        loc += " remapped #{canonic_file(map_file)}:#{map_line}"
      end
        
      [loc, line_no, text]
    end

    def print_location
      # if %w(c-call call).member?(@event)
      #   # FIXME: Fix Ruby so we don't need this workaround? 
      #   # See also where.rb
      #   opts = {}
      #   opts[:class] = @core.hook_arg if 
      #     'CFUNC' == @frame.type && @core.hook_arg && 0 == @frame_index 
      #   msg format_stack_call(@frame, opts) 
      # elsif 'raise' == @core.event
      #   msg @core.hook_arg.inspect if @core.hook_arg # Exception object
      # end

      text      = nil
      # source_container = frame_container(@frame, false)
      ev        = if @event.nil? || 0 != @frame_index
                    '  ' 
                  else
                    (EVENT2ICON[@event] || @event)
                  end

      @line_no  = @frame.location.line

      loc = source_location_info
      loc, @line_no, text = loc_and_text(loc)

      msg "#{ev} (#{loc})"

      # if %w(return c-return).member?(@core.event)
      #   retval = Trepan::Frame.value_returned(@frame, @core.event)
      #   msg 'R=> %s' % retval.inspect 
      # end
      
      if text && !text.strip.empty?
        msg text
        @line_no -= 1
      else
        show_bytecode
      end
    end

    def source_location_info
      filename  = @frame.location.method.active_path
      canonic_filename = 
        # if (0 == filename.index('(eval')) && frame.prev &&
        #     (eval_str = Trepan::Frame.eval_string(frame.prev))
        #   'eval ' + safe_repr(eval_str, 15)
        # else
          canonic_file(filename)
        # end
      loc = "#{canonic_filename}:#{@frame.location.line}"
      return loc
    end 

  end
end
