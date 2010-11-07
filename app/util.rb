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

    # When we are run via -Xdebug, $0 isn't set when the debugger is called.
    # It can however be found as Rubinius::Loader#script.
    def get_dollar_0
      if defined?($0)
        $0
      else
        locs = Rubinius::VM.backtrace(0, true).select do |loc| 
          loc.method.name == :main
        end
        locs.each do |loc|
          receiver = loc.instance_variable_get('@receiver')
          if receiver
            script = receiver.instance_variable_get('@script')
            return script if script
          end
        end
        return nil
      end
    end
    module_function :get_dollar_0
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
