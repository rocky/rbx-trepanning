# Copyright (C) 2010 Rocky Bernstein <rockyb@rubyforge.net>

class Trepan
  module Util

    def safe_repr(str, max, elipsis='... ')
      if str.is_a?(String) && str.size > max && !str.index("\n")
        "%s%s%s" % [ str[0...max/2], elipsis,  str[str.size-max/2..str.size]]
      else
        str
      end
    end
    module_function :safe_repr
    
    # Find user portion of script skipping over Rubinius code loading.
    # Unless hidestack is off, we don't show parts of the frame below this.
    def find_main_script(locs)
      (locs.size-1).downto(0) do |i|
        return locs.size - i - 1 if 'main.' == locs[i].describe_receiver &&
          :__script__ == locs[i].name
      end
      nil
    end
    module_function :find_main_script
  end
end

if __FILE__ == $0
  include Trepan::Util
  string = 'The time has come to talk of many things.'
  puts safe_repr(string, 50)
  puts safe_repr(string, 17)
  puts safe_repr(string.inspect, 17)
  puts safe_repr(string.inspect, 17, '')
end
