#!/usr/bin/env ruby
# GCD. We assume positive numbers
require 'rubygems'; require 'require_relative'
require_relative '../../lib/trepanning.rb'
$dbgr = Trepan.new(:server => true)
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
  return gcd(b-a, a)
end

a, b = ARGV[0..1].map {|arg| arg.to_i}
puts "The GCD of %d and %d is %d" % [a, b, gcd(a, b)]
