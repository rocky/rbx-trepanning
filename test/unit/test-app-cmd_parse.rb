#!/usr/bin/env ruby
require 'test/unit'
require 'rubygems'; require 'require_relative'
require_relative '../../app/cmd_parse'

class TestCmdParse < Test::Unit::TestCase

  # require_relative '../../lib/trepanning'
  def test_parse_location
    [['fn', [:fn, nil, nil]],
     ['fn 2', [:fn, :line, 2]],
     ['fn @5', [:fn, :offset, 5]],
     ['@3',   [nil, :offset, 3]],
     ['fn:6', [:fn, :line, 6]],
     ["#{__FILE__}:5", [:file, :line, 5]],
     ['fn:@15', [:fn, :offset, 15]],
    ].each do |location, expect|
      cp = parse_location(location)
      assert cp, "should be able to parse #{location} as a location"
      assert_equal(expect[0], cp.container_type, 
                   "mismatch container_type on #{location}")
      assert_equal(expect[1], cp.position_type, 
                   "mismatch position_type on #{location}")
      assert_equal(expect[2], cp.position, 
                   "mismatch position on #{location}")
    end
    
    # %w(0 1e10 a.b).each do |location|
    #   begin
    #     cp = CmdParse.new(name)
    #     assert_equal nil cp._location, 
    #     "should be able to parse #{name} as a location"
    #   end
    # end
  end
  
  module Testing
    def testing; 5 end
    module_function :testing
  end

  def test_parse_identifier
    %w(a a1 $global __FILE__ Constant).each do |name|
      cp = CmdParse.new(name)
      assert cp._identifier, "should be able to parse #{name} as an identifier"
    end
    %w(0 1e10 @10).each do |name|
      cp = CmdParse.new(name)
      assert_equal(true, !cp._identifier, 
                   "should not have been able to parse of #{name}")
    end
  end

  def test_parse_method
    [['Object', 0], ['A::B', 1], ['A::B::C', 2],
     ['A::B::C::D', 3], ['A::B.c', 2], ['A.b.c.d', 3]].each do |name, count|
      cp = CmdParse.new(name)
      assert cp._class_module_chain, "should be able to parse of #{name}"
      m = cp.result
      count.times do |i|
        assert m, "Chain item #{i} of #{name} should not be nil"
        m = m.chain[1]
      end
      assert_nil m.chain, "#{count} chain item in #{cp.result} should be nil"
    end
    ['A(5)'].each do |name|
      cp = CmdParse.new(name)
      cp._class_module_chain
      assert_not_equal(name, cp.result.name,
                   "should not have been able to parse of #{name}")
    end
  end

  include Trepan::CmdParser
  def test_method_name
    def five; 5 end
    %w(five Rubinius::VM.backtrace Kernel.eval
        Testing.testing Kernel::eval File.basename).each do |str|
      meth = meth_for_string(str, binding)
      assert meth.kind_of?(Method), "#{str} method's class should be Method, not #{meth.class}"
    end
    x = File
    def x.five; 5; end
    %w(x.basename x.five).each do |str|
      meth = meth_for_string(str, binding)
      assert meth.kind_of?(Method), "#{str} method's class should be Method, not #{meth.class}"
    end
    %w(Array.map).each do |str|
      meth = meth_for_string(str, binding)
      assert meth.kind_of?(UnboundMethod), "#{meth.class}"
    end
    %w(O5).each do |str|
      meth = meth_for_string(str, binding)
      assert_equal nil, meth, "should have found a method for #{str}"
    end
  end
end
