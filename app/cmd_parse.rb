# use_grammar.rb
require 'rubygems'
require 'citrus'
grammar_file = File.expand_path(File.join(File.dirname(__FILE__), 
                                          'cmd_parse.citrus'))
Citrus.require grammar_file

class Trepan
  module CmdParser
    # Given a Citrus parse object, return the method of that parse or raise a
    # Name error if we can't find a method. parent_class is the parent class of
    # the object we've found so far and "binding" is used if we need
    # to use eval to find the method.
    def resolve_method(match_data, bind, parent_class = nil)
      m = match_data
      name = m.value.name
      # DEBUG p  name
      errmsg = nil
      if m.value.type == :constant
        begin
          if parent_class
            klass = parent_class.const_get(m.value.chain[0])
          else
            errmsg = "Constant #{m} is not a class or module"
            raise NameError, errmsg unless m.value.chain[0]
            klass = eval(m.value.chain[0], bind)
          end
          errmsg = "Constant #{klass} is not a class or module" unless
          raise NameError, errmsg unless
            klass.kind_of?(Class) or klass.kind_of?(Module)
          m = m.value.chain[1]
          if klass.instance_methods.member?(:binding)
            bind = klass.bind
          elsif klass.private_instance_methods.member?(:binding)
            bind = klass.send(:binding)
          else
            bind = nil
          end
          resolve_method(m, bind, klass)
        rescue NameError 
          errmsg ||= "Can't resolve constant #{name}"
          raise NameError, errmsg
        end
      else
        is_class = 
          begin
            m.value.chain[0] && 
              Class == eval("#{m.value.chain[0]}.class", bind) 
          rescue 
            false
          end
        if is_class
          # Handles stuff like:
          #    x = File
          #    x.basename
          # Above, we tested we get a class back when we evalate m.value.chain[0]
          # below. So it is safe to run the eval.
          klass = eval("#{m.value.chain[0]}", bind)
          resolve_method(m.value.chain[1], klass.send(:binding), klass)
        else
          begin
            errmsg = "Can't get method for #{name.inspect}"
            # parent_class = eval('self', bind) if !parent_class && bind
            # p ['+++2', parent_class, parent_class.methods.member?(name)]
            meth = 
              if parent_class
                errmsg << "in #{parent_class}"
                if parent_class.respond_to?('instance_methods') && 
                    parent_class.instance_methods.member?(name)
                  parent_class.instance_method(name)
                else
                  parent_class.method(name)
                end
              else
                eval("self.method(#{name.inspect})", bind)
              end
            return meth
          rescue
            raise NameError, errmsg
          end
        end
      end
    end

    # Parse str and return the method associated with that.
    # Citrus::ParseError is returned if we can't parse str
    # and NameError is returned if we can't find a method
    # but we can parse the string.
    def meth_for_string(str, start_binding)
      begin 
        match = MethodName.parse(str, :root => :class_module_chain)
      rescue Citrus::ParseError
        return nil
      end
      resolve_method(match, start_binding)
    end
  end
end

if __FILE__ == $0
  # Demo it.
  %w(a a1 $global __FILE__ Constant 0 1e10 a.b).each do |name|
    begin
      match = MethodName.parse(name, :root => :identifier)
      p [name, match.value.type, 'succeeded']
    rescue Citrus::ParseError
      p [name, 'failed']
    end
  end
  
  %w(Object  A::B  A::B::C  A::B::C::D  A::B.c  A.b.c.d  A(5)
     Rubinius::VariableScope::method_visibility
     ).each do |name|
    begin
      match = MethodName.parse(name, :root => :class_module_chain)
      p [name, match.value.type, match.value.name, match.value.chain, 'succeeded']
      m = match.value.chain[1]
      while m
        p [m.value.name, m.value.type]
        m = m.value.chain[1]
      end
    rescue Citrus::ParseError
      p [name, 'failed']
    end
  end

  def five; 5 end
  include Trepan::CmdParser
  p meth_for_string('Array.map', binding)
  %w(five
     Rubinius::VM.backtrace
     Kernel.eval
     Kernel::eval).each do |str|
    meth = meth_for_string(str, binding)
    p meth
  end
  module Testing
    def testing; 5 end
    module_function :testing
  end
  p meth_for_string('Testing.testing', binding)  
  p meth_for_string('File.basename', binding)  
  x = File
  p meth_for_string('x.basename', binding)  
  def x.five; 5; end
  p  meth_for_string('x.five', binding)  
  p x.five

  match = MethodName.parse('5', :root => :line_number)
  p match.value

  match = MethodName.parse('@5', :root => :vm_offset)
  p match.value

  # Location stuff
  ['fn', 'fn 5', 'fn @5', '@5', '5'].each do |location|
    begin
      match = MethodName.parse(location, :root => :location)
      p [location, 'succeeded', match.value]
    rescue Citrus::ParseError
      p [location, 'failed']
    end
  end

end

