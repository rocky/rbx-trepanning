#!/usr/bin/env rake
# Are we Rubinius? We'll test by checking the specific function we need.
raise RuntimeError, 'This package is for Rubinius 1.2.1 or 1.2.2dev only!' unless
  Object.constants.include?('Rubinius') && 
  Rubinius.constants.include?('VM') && 
  %w(1.2.1 1.2.2dev).member?(Rubinius::VERSION)

require 'rubygems'
require 'rake/gempackagetask'
require 'rake/rdoctask'
require 'rake/testtask'

ROOT_DIR = File.dirname(__FILE__)
Gemspec_filename = 'rbx-trepanning.gemspec'
require File.join %W(#{ROOT_DIR} app options)

def gemspec
  @gemspec ||= eval(File.read(Gemspec_filename), binding, Gemspec_filename)
end

desc "Build the gem"
task :package=>:gem
task :gem=>:gemspec do
  Dir.chdir(ROOT_DIR) do
    sh "gem build #{Gemspec_filename}"
    FileUtils.mkdir_p 'pkg'
    FileUtils.mv("#{gemspec.file_name}", "pkg/")
  end
end

desc "Install the gem locally"
task :install => :gem do
  Dir.chdir(ROOT_DIR) do
    sh %{gem install --local pkg/#{gemspec.file_name}}
  end
end

require 'rbconfig'
RUBY_PATH = File.join(RbConfig::CONFIG['bindir'],  
                      RbConfig::CONFIG['RUBY_INSTALL_NAME'])

def run_standalone_ruby_files(list)
  puts '*' * 40
  list.each do |ruby_file|
    system(RUBY_PATH, ruby_file)
  end
end

def run_standalone_ruby_file(directory, opts={})
  puts ('*' * 10) + ' ' + directory + ' ' + ('*' * 10)
  Dir.chdir(directory) do
    Dir.glob('*.rb').each do |ruby_file|
      puts(('-' * 20) + ' ' + ruby_file + ' ' + ('-' * 20))
      system(RUBY_PATH, ruby_file)
      break if $?.exitstatus != 0 && !opts[:continue]
    end
  end
end

desc 'Create a GNU-style ChangeLog via git2cl'
task :ChangeLog do
  system('git log --pretty --numstat --summary | git2cl > ChangeLog')
end

desc 'Test units - the smaller tests'
Rake::TestTask.new(:'test:unit') do |t|
  t.test_files = FileList['test/unit/**/test-*.rb']
  # t.pattern = 'test/**/*test-*.rb' # instead of above
  t.options = '--verbose' if $VERBOSE
end

desc 'Test functional - the medium-sized tests'
Rake::TestTask.new(:'test:functional') do |t|
  t.test_files = FileList['test/functional/**/test-*.rb']
  t.options = '--verbose' if $VERBOSE
end

desc 'Test integration - end-to-end blackbox tests'
Rake::TestTask.new(:'test:integration') do |t|
  t.test_files = FileList['test/integration/**/test-*.rb']
  t.options = '--verbose' if $VERBOSE
end

desc 'Test everything - unit tests for now.'
task :default => :test
task :test do
  exceptions = %w(test:unit test:functional test:integration).collect do |task|
    begin
      Rake::Task[task].invoke
      nil
    rescue => e
      e
    end
  end.compact
  
  exceptions.each {|e| puts e;puts e.backtrace }
  raise "Test failures" unless exceptions.empty?
end

desc "Run each Ruby app file in standalone mode."
task :'check:app' do
  run_standalone_ruby_file(File.join(%W(#{ROOT_DIR} app)))
end

desc "Run each command in standalone mode."
task :'check:commands' do
  run_standalone_ruby_file(File.join(%W(#{ROOT_DIR} processor command)))
end

desc "Run each of the sub-sub commands in standalone mode."
task :'check:sub:commands' do
  p "#{ROOT_DIR}/processor/command/*_subcmd/*_subcmd/*.rb"
  Dir.glob("#{ROOT_DIR}/processor/command/*_subcmd").each do |sub_dir|
    run_standalone_ruby_file(sub_dir)
  end
end

desc "Run each processor Ruby file in standalone mode."
task :'check:processor' do
  run_standalone_ruby_file(File.join(%W(#{ROOT_DIR} processor)))
end

task :'check:functional' do
  run_standalone_ruby_file(File.join(%W(#{ROOT_DIR} test functional)))
end

desc "Run each unit test in standalone mode."
task :'check:unit' do
  run_standalone_ruby_file(File.join(%W(#{ROOT_DIR} test unit)))
end

desc "Generate the gemspec"
task :generate do
  puts gemspec.to_ruby
end

desc "Validate the gemspec"
task :gemspec do
  gemspec.validate
end

# ---------  RDoc Documentation ------
desc "Generate rdoc documentation"
Rake::RDocTask.new("rdoc") do |rdoc|
  rdoc.rdoc_dir = 'doc'
  rdoc.title    = "rbx-trepaning #{Trepan::VERSION} Documentation"

  rdoc.rdoc_files.include(%w(lib/trepanning.rb processor/*.rb
                             processor/command/*.rb
                             app/*.rb intf/*.rb io/*.rb 
                            ))
end

desc "Same as rdoc"
task :doc => :rdoc

task :clobber_package do
  FileUtils.rm_rf File.join(ROOT_DIR, 'pkg')
end

task :clobber_rdoc do
  FileUtils.rm_rf File.join(ROOT_DIR, 'doc')
end

desc "Remove built files"
task :clean => [:clobber_package, :clobber_rdoc]
