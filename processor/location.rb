# Copyright (C) 2010, 2011 Rocky Bernstein <rockyb@rubyforge.net>
require 'rubygems'; 
require 'pathname'  # For cleanpath
require 'linecache'
require 'require_relative'
require_relative 'disassemble'
require_relative 'msg'
require_relative 'frame'
require_relative '../app/file'
require_relative 'virtual'
class Trepan::CmdProcessor < Trepan::VirtualCmdProcessor

  def canonic_file(filename, resolve=true)
    # For now we want resolved filenames 
    if @settings[:basename] 
      return File.basename(filename)
    end
    if resolve
      filename = LineCache::map_file(filename)
      if !File.exist?(filename) 
        if (try_filename = find_load_path(filename))
          try_filename
        elsif (try_filename = resolve_file_with_dir(filename))
          try_filename
        else
          File.expand_path(Pathname.new(filename).cleanpath.to_s).
            gsub(/\.rbc$/, '.rb')
        end
      end
    else
      filename.gsub(/\.rbc$/, '.rb')
    end
  end

  # Return the text to the current source line.
  # FIXME: loc_and_text should call this rather than the other
  # way around.
  def current_source_text
    opts = {:reload_on_change => settings[:reload]}
    loc, junk, text = loc_and_text(source_location_info, opts)
    text
  end
  
  def resolve_file_with_dir(path_suffix)
    settings[:directory].split(/:/).each do |dir|
      dir = 
        if '$cwd' == dir
          Dir.pwd
        elsif '$cdir' == dir
          Rubinius::OS_STARTUP_DIR
        elsif '$rbx' == dir
          compiler_file = '/lib/compiler/compiler.rb'
          compiler_rb_path = 
            $LOADED_FEATURES.find{|f| f.end_with?(compiler_file)}
          if compiler_rb_path
            compiler_rb_path[0...-(compiler_file.size)]
          else
            nil
          end
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
  def line_at(filename, line_number, 
              opts = {
                :reload_on_change => @settings[:reload],
                :output => @settings[:highlight]
              })
    # We use linecache first to give precidence to user-remapped
    # file names
    line = LineCache::getline(filename, line_number, opts)
    unless line
      # Try using search directories (set with command "directory")
      if filename[0..0] != File::SEPARATOR
        try_filename = resolve_file_with_dir(filename) 
        if try_filename && 
            line = LineCache::getline(try_filename, line_number, opts) 
          LineCache::remap_file(filename, try_filename)
        end
      end
    end
    return nil unless line
    return line.lstrip.chomp
  end
  
  def loc_and_text(loc, opts=
                   {:reload_on_change => @settings[:reload],
                     :output => @settings[:highlight]
                   })
    
    vm_location = @frame.vm_location
    filename = vm_location.method.active_path
    line_no  = @frame.line
    static   = vm_location.static_scope
    opts[:compiled_method] = top_scope(@frame.method)
    
    if @frame.eval?
      file = LineCache::map_script(static.script)
      text = LineCache::getline(static.script, line_no, opts)
      loc += " remapped #{canonic_file(file)}:#{line_no}"
    else
      text = line_at(filename, line_no, opts)
      map_file, map_line = LineCache::map_file_line(filename, line_no)
      if [filename, line_no] != [map_file, map_line]
        loc += " remapped #{canonic_file(map_file)}:#{map_line}"
      end
    end
    [loc, line_no, text]
  end
  
  def format_location(event=@event, frame=@frame, frame_index=@frame_index)
    text      = nil
    ev        = if event.nil? || 0 != frame_index
                  '  ' 
                else
                  (EVENT2ICON[event] || event)
                end
    
    @line_no  = frame.line
    
    loc = source_location_info
    loc, @line_no, text = loc_and_text(loc)
    ip_str = frame.method ? " @#{frame.next_ip}" : ''
    
    "#{ev} (#{loc}#{ip_str})"
  end
  
  # FIXME: Use above format_location routine
  def print_location
    text      = nil
    ev        = if @event.nil? || 0 != @frame_index
                  '  ' 
                else
                  (EVENT2ICON[@event] || @event)
                end
    
    @line_no  = @frame.line
    
    loc = source_location_info
    loc, @line_no, text = loc_and_text(loc)
    ip_str = frame.method ? " @#{frame.next_ip}" : ''
    
    msg "#{ev} (#{loc}#{ip_str})"
    
    # if %w(return c-return).member?(@core.event)
    #   retval = Trepan::Frame.value_returned(@frame, @core.event)
    #   msg 'R=> %s' % retval.inspect 
    # end
    
    if text && !text.strip.empty?
      old_maxstring = @settings[:maxstring]
      @settings[:maxstring] = -1
      msg text
      @settings[:maxstring] = old_maxstring
      @line_no -= 1
    else
      show_bytecode
    end
  end
  
  def source_location_info
    filename  = @frame.vm_location.method.active_path
    canonic_filename = 
      if @frame.eval?
        'eval ' + safe_repr(@frame.eval_string.gsub("\n", ';').inspect, 20)
      else
        canonic_file(filename, false)
      end
    loc = "#{canonic_filename}:#{@frame.line}"
    return loc
  end 
end

if __FILE__ == $0 && caller.size == 0
  # Demo it.
  require_relative './mock'
  dbgr = MockDebugger::MockDebugger.new
  proc = Trepan::CmdProcessor.new(dbgr)
  proc.settings = {:directory => '$rbx:$cdir:$cwd'}
  proc.frame_initialize
  frame = Trepan::Frame.new(self, 1, Rubinius::VM.backtrace(0)[0])
  proc.instance_variable_set('@frame', frame)

  puts proc.canonic_file(__FILE__)
  puts proc.canonic_file('lib/compiler/ast.rb')
  proc.settings[:basename] = true
  puts proc.canonic_file(__FILE__)
  puts proc.current_source_text
  xx = eval <<-END
     proc.frame_initialize
     frame = Trepan::Frame.new(self, 1, Rubinius::VM.backtrace(0)[0])
     proc.instance_variable_set('@frame', frame)
     puts proc.current_source_text
  END
end
