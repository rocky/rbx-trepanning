# Copyright (C) 2011 Rocky Bernstein <rockyb@rubyforge.net>

# Trepan command list validation routines.  A String type is
# usually passed in as the argument to validation routines.

require 'rubygems'
require 'require_relative'

require_relative './validate'

class Trepan
  class CmdProcessor < VirtualCmdProcessor

    # If last is less than first, assume last is a count rather than an
    # end line number. If last is negative, range is [first+last..first].
    def adjust_last(first, last)
      last < first ? first + last - 1 : last
    end

    # Parse a list command. On success return:
    #   - the line number - a Fixnum
    #   - file name
    #   - last line
    def parse_list_cmd(position_str, listsize, center_correction=0)
      cm = nil
      if position_str.empty?
        filename = frame.file
        first = [1, frame.line - center_correction].max
      else
        list_cmd_parse = parse_list(position_str,
                                    :file_exists_proc => file_exists_proc)
        return [nil] * 3 unless list_cmd_parse
        last = list_cmd_parse.num
        position = list_cmd_parse.position

        if position.is_a?(String)
          if position == '-'
            return no_frame_msg_for_list unless frame.line
            first = [1, frame.line - 2*listsize - 1].max
          elsif position == '.'
            return no_frame_msg_for_list unless frame.line
            if (second = list_cmd_parse.num)
              first = frame.line 
              last = adjust_last(first, second)
            else
              first = [1, frame.line - center_correction].max
              last = first + listsize - 1
            end
          end
          filename = frame.file
        else
          meth_or_frame, filename, offset, offset_type = 
            parse_position(position)
          return [nil] * 3 unless filename
          if offset_type == :line
            first = offset
          elsif meth_or_frame
            first, vm_offset = 
              position_to_line_and_offset(meth_or_frame, filename, position, 
                                          offset_type)
            unless first
              errmsg("Unable to get location in #{meth_or_frame}")
              return [nil] * 4 
            end
          elsif !offset 
            first = 1
          else
            errmsg("Unable to parse list position #{position_str}")
            return [nil] * 4
          end
        end
      end
      if last
        first, last = [first + last, first] if last < 0
        last = adjust_last(first, last)
      else
        first = [1, first - center_correction].max 
        last = first + listsize - 1 unless last
      end
      LineCache::cache(filename) unless LineCache::cached?(filename)
      return [filename, first, last]
    end
    
    def no_frame_msg_for_list
      errmsg("No Ruby program loaded.")
      return nil, nil, nil
    end
    
  end
end

if __FILE__ == $0
  # Demo it.
  require_relative 'mock'
  require_relative 'frame'
  dbgr, cmd = MockDebugger::setup('exit', false)
  cmdproc  = cmd.proc
  cmdproc.frame_initialize
  cmdproc.instance_variable_set('@settings', 
                                Trepan::CmdProcessor::DEFAULT_SETTINGS)
  def foo; 5 end
  def cmdproc.errmsg(msg)
    puts msg
  end
  puts '-' * 20
  p cmdproc.parse_list_cmd('.', 10)
  p cmdproc.parse_list_cmd('-', 10)
  p cmdproc.parse_list_cmd('foo', 10)
  p cmdproc.parse_list_cmd('@0', 10)
  p cmdproc.parse_list_cmd("#{__LINE__}", 10)
  p cmdproc.parse_list_cmd("#{__FILE__}   @0", 10)
  p cmdproc.parse_list_cmd("#{__FILE__}:#{__LINE__}", 10)
  p cmdproc.parse_list_cmd("#{__FILE__} #{__LINE__}", 10)
  p cmdproc.parse_list_cmd("cmdproc.errmsg", 10)
  p cmdproc.parse_list_cmd("cmdproc.errmsg:@0", 10)
  p cmdproc.parse_list_cmd("cmdproc.errmsg:@0", -10)
end
