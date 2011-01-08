#!/usr/bin/env ruby
require 'test/unit'
require 'rubygems'; require 'require_relative'

# Unit test for io/tcpserver.rb
require_relative '../../io/tcpfns'
require_relative '../../io/tcpserver'
require_relative '../../io/tcpfns'

class TestTCPDbgServer < Test::Unit::TestCase

  include Trepanning::TCPPacking

  def test_basic
    server = Trepan::TCPDbgServer.new(STDIN, 
                                      { :open => false,
                                        :port => 1027,
                                        :host => 'localhost'
                                      })
    server.open
    threads = []
    msgs = %w(one two three)
    Thread.new do
      msgs.each do |msg|
        begin
          line = server.read_msg.chomp
          assert_equal(msg, line)
        rescue EOFError
          puts 'Got EOF'
          break
        end
      end
    end
    threads << Thread.new do 
      t = TCPSocket.new('localhost', 1027)
      msgs.each do |msg|
        begin
          t.puts(pack_msg(msg))
        rescue EOFError
          puts "Got EOF"
          break
        rescue Exception => e
          puts "Got #{e}"
          break
        end
      end
      t.close
    end
    threads.each {|t| t.join }
    server.close
  end
end
