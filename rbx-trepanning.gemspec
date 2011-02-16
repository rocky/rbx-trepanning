# -*- Ruby -*-
# -*- encoding: utf-8 -*-
require 'rake'
require 'rubygems' unless 
  Object.const_defined?(:Gem)
require File.dirname(__FILE__) + "/app/options" unless 
  Object.const_defined?(:'Trepan')

Gem::Specification.new do |s|
  s.add_dependency('columnize')
  s.add_dependency('diff-lcs') # For testing only
  s.add_dependency('rbx-require-relative')
  s.add_dependency('rbx-linecache', '~>1.0')
  s.authors      = ['R. Bernstein']
  s.date         = Time.now
  s.description = <<-EOF
A modular, testable, Ruby debugger using some of good ideas from
ruby-debug, other debuggers, and Ruby Rails.

Some of the core debugger concepts have been rethought. As a result,
some of this may be experimental.

This version works only on Rubinus 1.2.1 or higher.
EOF
  ## s.add_dependency('diff-lcs') # For testing only
  s.authors       = ['R. Bernstein']
  s.email         = 'rockyb@rubyforge.net'
  s.executables = `git ls-files -- bin/*`.split("\n").map{ 
    |f| File.basename(f) }
  s.files         = `git ls-files`.split("\n")
  s.homepage      = 'http://wiki.github.com/rocky/rbx-trepanning'
  s.name          = 'rbx-trepanning'
  s.license       = 'MIT'
  s.platform      = Gem::Platform::new ['universal', 'rubinius', '1.2']
  s.require_paths = ['lib']
  s.required_ruby_version = '~> 1.8.7'
  s.summary      = 'Trepan Ruby Debugger for Rubinius 1.2.1 and higher'
  s.test_files   = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.version      = Trepan::VERSION
end
