# -*- Ruby -*-
# -*- encoding: utf-8 -*-
require 'rake'
require 'rubygems' unless 
  Object.const_defined?(:Gem)
require File.dirname(__FILE__) + "/lib/trepanning" unless 
  Object.const_defined?(:'Trepan')

FILES = FileList[
  # 'README.textile',
  'ChangeLog',
  'LICENSE',
  'NEWS',
  'Rakefile',
  'THANKS',
  'app/*',
  'bin/*',
  'data/*',
  'interface/*',
  'io/*',
  'lib/*',
  'processor/**/*.rb',
  'test/**/*.rb',
]                        


Gem::Specification.new do |spec|
  spec.add_dependency('columnize')
  spec.add_dependency('rbx-require-relative')
  spec.add_dependency('rbx-linecache')
  spec.authors      = ['R. Bernstein']
  spec.date         = Time.now
  spec.description = <<-EOF
A modular, testable, Ruby debugger using some of the best ideas from ruby-debug, other debuggers, and Ruby Rails. 

Some of the core debugger concepts have been rethought. As a result, some of this may be experimental.

This version works only with a patched version of Ruby 1.9.2 and rb-threadframe.
EOF
  ## spec.add_dependency('diff-lcs') # For testing only
  spec.author       = 'R. Bernstein'
  spec.bindir       = 'bin'
  spec.email        = 'rockyb@rubyforge.net'
  spec.executables = ['trepan']
  spec.files        = FILES.to_a  
  spec.has_rdoc     = true
  spec.homepage     = 'http://wiki.github.com/rocky/rbx-trepanning'
  spec.name         = 'rbx-trepanning'
  spec.license      = 'MIT'
  spec.platform     = Gem::Platform::RUBY
  spec.require_path = 'lib'
  spec.required_ruby_version = '~> 1.8.7'
  spec.summary      = 'Trepan Ruby Debugger for Rubinius 1.1'
  spec.version      = Trepan::VERSION

  # Make the readme file the start page for the generated html
  ## spec.rdoc_options += %w(--main README)
  spec.rdoc_options += ['--title', "Trepan #{Trepan::VERSION} Documentation"]

end
