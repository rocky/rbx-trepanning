#!/usr/bin/env ruby
require 'rubygems'; require 'require_relative'
require_relative '../../lib/trepanning.rb'
DATA_DIR = File.join(File.dirname(RequireRelative::abs_file), %w(.. data))
cmdfile = File.join(DATA_DIR, 'inline-call.cmd')
$dbgr = Trepan.new(:nx => true, :cmdfiles => [cmdfile])
# GCD. We assume positive numbers
def gcd(a, b)
  $dbgr.debugger
  # Make: a <= b
  if a > b
    a, b = [b, a]
  end

  return nil if a <= 0

  if a == 1 or b-a == 0
    return a
  end
end

a, b = ARGV[0..1].map {|arg| arg.to_i}
puts "The GCD of %d and %d is %d" % [a, b, gcd(a, b)]
