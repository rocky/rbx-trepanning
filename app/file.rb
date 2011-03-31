# -*- coding: utf-8 -*-
# Copyright (C) 2010, 2011 Rocky Bernstein <rockyb@rubyforge.net>
# Things related to file/module status

module Trepanning
  module FileName
    def find_load_path(filename)
      cl = Rubinius::CodeLoader.new(filename)
      if cl.verify_load_path(filename)
        cl.instance_variable_get('@load_path')
      else
        nil
      end
    end
  end
end
if __FILE__ == $0
  include Trepanning::FileName
  require 'tmpdir.rb'
  [__FILE__, 'tmpdir.rb'].each do |name|
    p find_load_path(name)
  end
end
