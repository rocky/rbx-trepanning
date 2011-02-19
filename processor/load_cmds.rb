# -*- coding: utf-8 -*-
# Copyright (C) 2010, 2011 Rocky Bernstein <rockyb@rubyforge.net> 

# Part of Trepan::CmdProcess that loads up debugger commands from
# builtin and user directories.  
# Sets @commands, @aliases, @macros
require 'rubygems'; require 'require_relative'
require_relative '../app/complete'
class Trepan
  class CmdProcessor

    attr_reader   :aliases         # Hash[String] of command names
                                   # indexed by alias name
    attr_reader   :commands        # Hash[String] of command objects
                                   # indexed by name
    attr_reader   :macros          # Hash[String] of Proc objects 
                                   # indexed by macro name.
    
    # "initialize" for multi-file class. Called from main.rb's "initialize".
    def load_cmds_initialize
      @commands = {}
      @aliases = {}
      @macros = {}

      cmd_dirs = [ File.join(File.dirname(__FILE__), 'command') ]
      cmd_dirs <<  @settings[:user_cmd_dir] if @settings[:user_cmd_dir]
      cmd_dirs.each do |cmd_dir| 
        load_debugger_commands(cmd_dir) if File.directory?(cmd_dir)
      end
    end

    # Loads in debugger commands by require'ing each ruby file in the
    # 'command' directory. Then a new instance of each class of the 
    # form Trepan::xxCommand is added to @commands and that array
    # is returned.
    def load_debugger_commands(file_or_dir)
      if File.directory?(file_or_dir)
        dir = File.expand_path(file_or_dir)
        Dir.glob(File.join(dir, '*.rb')).each do |rb| 
          # We use require so that multiple calls have no effect.
          require rb
        end
      elsif File.readable?(file_or_dir)
        # We use load in case we are reloading. 
        # 'require' would not be effective here
        load file_or_dir
      else
        return false
      end
      # Instantiate each Command class found by the above require(s).
      Trepan::Command.constants.grep(/.Command$/).each do |name|
        klass = Trepan::Command.const_get(name)
        cmd = klass.send(:new, self)

        # Add to list of commands and aliases.
        cmd_name = klass.const_get(:NAME)
        if klass.constants.member?('ALIASES')
          aliases= klass.const_get('ALIASES')
          aliases.each {|a| @aliases[a] = cmd_name}
        end
        @commands[cmd_name] = cmd
      end
    end

    # Looks up cmd_array[0] in @commands and runs that. We do lots of 
    # validity testing on cmd_array.
    def run_cmd(cmd_array)
      unless cmd_array.is_a?(Array)
        errmsg "run_cmd argument should be an Array, got: #{cmd_array.class}"
        return
      end
      if cmd_array.detect{|item| !item.is_a?(String)}
        errmsg "run_cmd argument Array should only contain strings. " + 
          "Got #{cmd_array.inspect}"
        return
      end
      if cmd_array.empty?
        errmsg "run_cmd Array should have at least one item. " + 
          "Got: #{cmd_array.inspect}"
        return
      end
      cmd_name = cmd_array[0]
      if @commands.member?(cmd_name)
        @commands[cmd_name].run(cmd_array)
      end
    end

    # Handle initial completion. We draw from the commands, aliases,
    # and macros for completion. However we won't include aliases which
    # are prefixes of other commands.
    def complete(str, last_token)
      next_blank_pos, token = Trepan::Complete.next_token(str, 0)
      return [''] if token.empty? && !last_token.empty?
      match_pairs = Trepan::Complete.complete_token_with_next(@commands,
                                                               token)
      match_hash = {}
      match_pairs.each do |pair|
        match_hash[pair[0]] = pair[1]
      end
      alias_pairs = Trepan::Complete.
        complete_token_filtered_with_next(@aliases, token, match_hash,
                                          @commands)
      match_pairs += alias_pairs
      if str[next_blank_pos..-1].empty?
        return match_pairs.map{|pair| pair[0]}.sort
      else
        alias_pairs.each do |pair|
          match_hash[pair[0]] = pair[1]
        end
      end
      if match_pairs.size > 1
        # FIXME: figure out what to do here.
        # Matched multiple items in the middle of the string
        # We can't handle this so do nothing.
        return []
        # return match_pairs.map do |name, cmd|
        #   ["#{name} #{args[1..-1].join(' ')}"]
        # end
      end
      # match_pairs.size == 1
      next_complete(str, next_blank_pos, match_pairs[0][1], last_token)
    end

    def next_complete(str, next_blank_pos, cmd, last_token)
      next_blank_pos, token = Trepan::Complete.next_token(str, next_blank_pos)
      return [] if token.empty? && !last_token.empty?
      
      if cmd.respond_to?(:complete_token_with_next) 
        match_pairs = cmd.complete_token_with_next(token)
        return [] if match_pairs.empty?
        if str[next_blank_pos..-1].rstrip.empty? && 
            (token.empty? || token == last_token)
          return match_pairs.map { |completion, junk| completion }
        else
          if match_pairs.size == 1
            return next_complete(str, next_blank_pos, match_pairs[0][1], 
                                 last_token)
          else
            # FIXME: figure out what to do here.
            # Matched multiple items in the middle of the string
            # We can't handle this so do nothing.
            return []
          end
        end
      elsif cmd.respond_to?(:complete)
        matches = cmd.complete(token)
        return [] if matches.empty?
        if str[next_blank_pos..-1].rstrip.empty? && 
            (token.empty? || token == last_token)
          return matches
        else
          # FIXME: figure out what to do here.
          # Matched multiple items in the middle of the string
          # We can't handle this so do nothing.
          return []
        end
      else
        return []
      end
    end
  end
end
if __FILE__ == $0
  class Trepan::CmdProcessor
    def initialize(core, settings={})
    end
  end

  cmdproc = Trepan::CmdProcessor.new(nil)
  cmddir = File.join(File.dirname(__FILE__), 'command')
  cmdproc.instance_variable_set('@settings', {})
  cmdproc.load_cmds_initialize
  require 'columnize'
  puts Columnize.columnize(cmdproc.commands.keys.sort)
  puts '=' * 20
  puts Columnize.columnize(cmdproc.aliases.keys.sort)
  puts '=' * 20

  def cmdproc.errmsg(mess)
    puts "** #{mess}"
  end

  def cmdproc.msg(mess)
    puts mess
  end

  cmdproc.run_cmd('foo')  # Invalid - not an Array
  cmdproc.run_cmd([])     # Invalid - empty Array
  cmdproc.run_cmd(['list', 5])  # Invalid - nonstring arg
  p cmdproc.complete("d")
  p cmdproc.complete("sho d")
  p cmdproc.complete('')
end
