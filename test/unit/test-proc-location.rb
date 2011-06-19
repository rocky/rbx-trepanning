#!/usr/bin/env ruby
require 'test/unit'
require 'rubygems'; require 'require_relative'
require 'linecache'
require_relative '../../processor/location'
require_relative 'cmd-helper'

# Test Trepan::CmdProcessor location portion
class TestCmdProcessorLocation < Test::Unit::TestCase

  include UnitHelper
  def setup
    common_setup
    @file ||= File.basename(__FILE__)
  end

  # Test resolve_file_with_dir() and line_at()
  def test_line_at
    @cmdproc.settings[:directory] = ''
    assert_equal(nil, @cmdproc.resolve_file_with_dir(@file))
    if File.expand_path(Dir.pwd) == File.expand_path(File.dirname(__FILE__))
      line = @cmdproc.line_at(@file, __LINE__)
      assert_match(/line = @cmdproc.line_at/, line)
    else
      assert_equal(nil, @cmdproc.line_at(@file, __LINE__))
    end
    dir = @cmdproc.settings[:directory] = File.dirname(__FILE__)
    assert_equal(File.join(dir, @file), 
                 @cmdproc.resolve_file_with_dir('test-proc-location.rb'))
    test_line = 'test_line'
    line = @cmdproc.line_at(@file, __LINE__-1)
    assert_match(/#{line}/, line)
  end

  def test_loc_and_text
    @cmdproc.frame_index = 0
    @cmdproc.frame_initialize
    @cmdproc.frame_setup
    LineCache::clear_file_cache
    dir = @cmdproc.settings[:directory] = File.dirname(__FILE__)
    loc, line_no, text = @cmdproc.loc_and_text('hi')
    assert loc and line_no.is_a?(Fixnum) and text 
    assert @cmdproc.current_source_text
    # FIXME test that filename remapping works.
  end

  def test_canonic_file
    @cmdproc.settings[:basename] = false
    assert_equal __FILE__, @cmdproc.canonic_file(__FILE__)
    assert @cmdproc.canonic_file('lib/compiler/ast.rb')
    @cmdproc.settings[:basename] = true
    assert_equal File.basename(__FILE__), @cmdproc.canonic_file(__FILE__)
    assert_equal 'ast.rb', @cmdproc.canonic_file('lib/compiler/ast.rb')
  end


  def test_eval_current_source_text
    eval <<-EOE
      @cmdproc.frame_index = 0
      @cmdproc.frame_initialize
      @cmdproc.frame_setup
      LineCache::clear_file_cache
      assert @cmdproc.current_source_text
    EOE
  end

end
