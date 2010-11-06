# Copyright (C) 2010 Rocky Bernstein <rockyb@rubyforge.net>
require 'rubygems'; require 'require_relative'
require 'set'
## require_relative '../app/core'
class Trepan
  class CmdProcessor

    attr_accessor :ignore_methods  # Hash[Method inspect string] ->
                                   # String action. Methods we don't
                                   # want to ever stop in.
    attr_accessor :stop_condition  # String or nil. When not nil
                                   # this has to eval non-nil
                                   # in order to stop.
    attr_accessor :stop_events     # Set or nil. If not nil, only
                                   # events in this set will be
                                   # considered for stopping. This is
                                   # like core.step_events (which
                                   # could be used instead), but it is
                                   # a set of event names rather than
                                   # a bitmask and it is intended to
                                   # be more temporarily changed via
                                   # "step>" or "step!" commands.
    attr_accessor :step_count
    attr_accessor :to_method
                                  
    # # Does whatever needs to be done to set to continue program
    # # execution.
    # # FIXME: turn line_number into a condition.

    def continue(how_to_continue)
      @next_thread     = nil
      @step_count      = -1    # No more event stepping
      @return_to_program = how_to_continue
    end

    # Does whatever setup needs to be done to set to ignore stepping
    # to the finish of the current method. Elsewhere in
    # "skipping_step?" we do the checking.
    def finish(level_count=0, opts={})
      step_to_return
      continue('finish')
      @next_thread       = @current_thread

      # # Try high-speed (run-time-assisted) method
      # @frame.trace_off   = true  # No more tracing in this frame
      # @frame.return_stop = true  # don't need to 
    end

    # # Does whatever needs to be done to set to "next" program
    # # execution.
    # def next(step_count=1, opts={})
    #   step(step_count, opts)
    #   @next_thread     = Thread.current
    # end

    # Does whatever needs to be done to set to step program
    # execution.
    def step(how_to_continue, step_count=1, opts={}, condition=nil)
      continue(how_to_continue)
      @step_count = step_count
      @different_pos   = opts[:different_pos] if 
        opts.keys.member?(:different_pos)
      @stop_condition  = condition
      @stop_events     = opts[:stop_events]   if 
        opts.keys.member?(:stop_events)
      @to_method       = opts[:to_method]
    end

    def quit(cmd='exit')
      @next_level      = 32000 # I'm guessing the stack size can't
                               # ever reach this
      @next_thread     = nil
      @step_count      = -1    # No more event stepping
      @leave_cmd_loop  = true  # Break out of the processor command loop.
      @settings[:autoirb] = false
      @cmdloop_prehooks.delete_by_name('autoirb')
      @commands['exit'].run([cmd])
    end

    def parse_next_step_suffix(step_cmd)
      opts = {}
      case step_cmd[-1..-1]
      when '-'
        opts[:different_pos] = false
      when '+'
        opts[:different_pos] = 'nostack'
      when '='
        opts[:different_pos] = true
      when '!'
        opts[:stop_events] = Set.new(%w(raise))
      when '<'
        opts[:stop_events] = Set.new(%w(c-return return))
      when '>'
        opts[:stop_events] = Set.new(%w(c-call call))
        if step_cmd.size > 1 && step_cmd[-2..-2] == '<'
          opts[:stop_events] = Set.new(%w(c-call c-return call return))
        else
          opts[:stop_events] = Set.new(%w(c-call call))
        end
      end
      return opts
    end

    def running_initialize
      @ignore_methods  = {}

      @step_count      = 0
      @stop_condition  = nil
      @stop_events     = nil
      @to_method       = nil
    end

    # If we are not in some kind of steppable event, return 
    # false. If we are in a steppable event, update step state
    # and return true if the step count is 0 and other conditions
    # like the @settings[:different] are met.
    def stepping_skip?
      # @settings[:debugskip] = true
      if @step_count < 0  
        # We may eventually stop for some other reason, but it's not
        # because we were stepping here.
        return false 
      end

      # if @settings[:debugskip]
      #   msg "diff: #{@different_pos}, event: #{@event}" 
      #   msg "step_count  : #{@step_count}" 
      #   msg "next_thread : #{@next_thread.inspect}, thread: #{@current_thread}" 
      # end

      mi = frame.method.inspect
      @ignore_methods.each do |m, val|
        if m == mi
          @return_to_program = val
          return true
        end
      end

      # Only skip on these kinds of events
      unless %w(step-call line).include?(@event)
        return false
      end

      # We are in some kind of stepping event, so do whatever we
      # do to record that we've hit the step. Whether we decide
      # to stop, will be done after recording the step took place.
      @step_count -= 1 unless step_count == 0
      new_pos = [@frame.file, @frame.line,
                 @stack_size, @current_thread, @event]


      # Decide whether this step is skippable.
      skip_val = false

      if @settings[:debugskip]
        msg("last: #{@last_pos.inspect}, ")
        msg("new:  #{new_pos.inspect}")
        msg("skip: #{skip_val.inspect}, event: #{@event}")
      end

      @last_pos[2] = new_pos[2] if 'nostack' == @different_pos
      condition_met = @step_count == 0

      #     if @stop_condition
      #       puts 'stop_cond' if @settings[:'debugskip']
      #       debug_eval_no_errmsg(@stop_condition)
      #     elsif @to_method
      #       puts "method #{@frame.method} #{@to_method}" if 
      #         @settings[:'debugskip']
      #       @frame.method == @to_method
      #     else
      #       puts 'uncond' if @settings[:'debugskip']
      #       true
      #     end
          
      #   msg("condition_met: #{condition_met}, last: #{@last_pos}, " +
      #        "new: #{new_pos}, different #{@different_pos.inspect}") if 
      #     @settings[:'debugskip']
      skip_val = ((@last_pos[0..3] == new_pos[0..3] && @different_pos) ||
                  !condition_met)
      msg("skip_val: #{skip_val}, count #{@step_count}") if 
        @settings[:debugskip]

      @last_pos = new_pos

      unless skip_val
        # Set up the default values for the
        # next time we consider step skipping.
        @different_pos = @settings[:different]
        # @stop_events   = nil
      end

      @return_to_program = 'step' if skip_val && !@return_to_program
      return skip_val
    end

  end
end
