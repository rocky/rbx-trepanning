# Copyright (C) 2010 Rocky Bernstein <rockyb@rubyforge.net>
class Trepan
  module Util

    def safe_repr(str, max, suffix='...')
      if str.is_a?(String) && str.size > max && !str.index("\n")
        char = str[0..0]
        opt_quote = 
          if '"' == char || "'" == char
            max -= 1
            char
          else
            ''
          end
        "%s%s%s" % [ str[0...max], opt_quote, suffix ]
      else
        str
      end
    end

    # Find user portion of script skipping over Rubinius code loading.
    # Unless hidestack is off, we don't show parts of the frame below this.
    def find_main_script(locs)
      (locs.size-1).downto(0) do |i|
        return locs.size - i - 1 if 'main.' == locs[i].describe_receiver &&
          :__script__ == locs[i].name
      end
      nil
    end

    module_function :safe_repr

  end
end

if __FILE__ == $0
  include Trepan::Util
  string = 'The time has come to talk of many things.'
  puts safe_repr(string, 50)
  puts safe_repr(string, 17)
  puts safe_repr(string.inspect, 17)
  puts safe_repr(string.inspect, 17, '')

  locs = Rubinius::VM.backtrace(0, true)
  locs.each_with_index do |loc, i|
    puts "#{i} #{loc.describe_receiver} #{loc.name}"
  end

  i = find_main_script(locs)
  if i
    puts "start is at #{i}"
  else
    puts "Didn't find start in the above"
  end
end
