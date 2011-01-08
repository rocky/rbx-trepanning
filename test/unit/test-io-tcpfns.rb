#!/usr/bin/env ruby
require 'test/unit'
require 'rubygems'; require 'require_relative'

# Unit test for io/tcpfns.rb

require_relative '../../io/tcpfns'

class TestTCPPacking < Test::Unit::TestCase

  include Trepanning::TCPPacking

  def test_pack_unpack
    msg = "Hi there!"
    assert_equal unpack_msg(pack_msg(msg))[1], msg
  end
end
