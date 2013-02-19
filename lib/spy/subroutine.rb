module Spy
  class Subroutine
    CallLog = Struct.new(:object, :args, :block)
    attr_reader :base_object, :method_name, :calls, :original_method, :opts
    def initialize(object, method_name)
      @was_hooked = false
      @base_object, @method_name = object, method_name
      reset!
    end

    # hooks the method into the object and stashes original method if it exists
    # @param opts [Hash{force => false, visibility => nil}] set :force => true if you want it to ignore if the method exists, or visibility to [:public, :protected, :private] to overwride current visibility
    # @return self
    def hook(opts = {})
      @opts = opts
      raise "#{base_object} method '#{method_name}' has already been hooked" if hooked?
      opts[:force] ||= base_object.is_a?(Double)
      if base_object.respond_to?(method_name, true) || !opts[:force]
        @original_method = base_object.method(method_name)
      end

      opts[:visibility] ||= method_visibility

      __method_spy__ = self
      base_object.define_singleton_method(method_name) do |*__spy_args, &block|
        if __spy_args.first === SECRET_SPY_KEY
          __method_spy__
        else
          __method_spy__.invoke(self,__spy_args,block)
        end
      end

      base_object.singleton_class.send(opts[:visibility], method_name) if opts[:visibility]

      Agency.instance.recruit(self)
      @was_hooked = true
      self
    end

    # unhooks method from object
    # @return self
    def unhook
      raise "#{method_name} method has not been hooked" unless hooked?
      if original_method && original_method.owner == base_object.singleton_class
        base_object.define_singleton_method(method_name, original_method)
        base_object.singleton_class.send(method_visibility, method_name) if method_visibility
      else
        base_object.singleton_class.send(:remove_method, method_name)
      end
      clear_method!
      Agency.instance.retire(self)
      self
    end

    # is the spy hooked?
    # @return Boolean
    def hooked?
      self == self.class.get(base_object, method_name)
    end

    # sets the return value of given spied method
    # @params return value
    # @params return block
    # @return self
    def and_return(value = nil, &block)
      if block_given?
        raise ArgumentError.new("value and block conflict. Choose one") if !value.nil?
        @plan = block
      else
        @plan = Proc.new { value }
      end
      self
    end

    def and_yield(*args)
      yield eval_context = Object.new if block_given?
      @plan = Proc.new do |&block|
        eval_context.instance_exec(*args, &block)
      end
      self
    end

    # tells the spy to call the original method
    # @return self
    def and_call_through
      raise "can only call through if original method is set" unless method_visibility
      if original_method
        @plan = original_method
      else
        @plan = Proc.new do |*args, &block|
          base_object.send(:method_missing, method_name, *args, &block)
        end
      end
      self
    end

    def and_raise(exception = RuntimeError, message = nil)
      if exception.respond_to?(:exception)
        exception = message ? exception.exception(message) : exception.exception
      end

      @plan = Proc.new { raise exception }
    end

    def and_throw(*args)
      @plan = Proc.new { throw(*args) }
      self
    end

    def has_been_called?
      raise "was never hooked" unless @was_hooked
      calls.size > 0
    end

    # check if the method was called with the exact arguments
    def has_been_called_with?(*args)
      raise "was never hooked" unless @was_hooked
      calls.any? do |call_log|
        call_log.args == args
      end
    end

    # invoke that the method has been called. You really shouldn't use this
    # method.
    def invoke(object, args, block)
      check_arity!(args.size)
      calls << CallLog.new(object, args, block)
      default_return_val = nil
      @plan ? @plan.call(*args, &block) : default_return_val
    end

    # reset the call log
    def reset!
      @calls = []
      clear_method!
      true
    end

    private

    def call_with_yield(&block)
      raise "no block sent"  unless block
      value = nil
      @args_to_yield.each do |args|
        if block.arity > -1 && args.length != block.arity
          @error_generator.raise_wrong_arity_error args, block.arity
        end
        value = @eval_context ? @eval_context.instance_exec(*args, &block) : block.call(*args)
      end
      value
    end

    def clear_method!
      @hooked = false
      @opts = @original_method = @arity_range = @method_visibility = nil
    end

    def method_visibility
      @method_visibility ||=
        if base_object.respond_to?(method_name)
          if original_method && original_method.owner.protected_method_defined?(method_name)
            :protected
          else
            :public
          end
        elsif base_object.respond_to?(method_name, true)
          :private
        end
    end

    def check_arity!(arity)
      self.class.check_arity_against_range!(arity_range, arity)
    end

    def arity_range
      @arity_range ||= self.class.arity_range_of(original_method) if original_method
    end

    class << self
      def arity_range_of(block)
        raise "#{block.inspect} does not respond to :parameters" unless block.respond_to?(:parameters)
        min = max = 0
        block.parameters.each do |type,_|
          case type
          when :req
            min += 1
            max += 1
          when :opt
            max += 1
          when :rest
            max = Float::INFINITY
          end
        end
        (min..max)
      end

      def check_arity_against_range!(arity_range, arity)
        return unless arity_range
        if arity < arity_range.min
          raise ArgumentError.new("wrong number of arguments (#{arity} for #{arity_range.min})")
        elsif arity > arity_range.max
          raise ArgumentError.new("wrong number of arguments (#{arity} for #{arity_range.max})")
        end
      end

      SPY_METHOD_PARAMS = [[:rest, :__spy_args], [:block, :block]]

      def get(base_object, method_name)
        if (base_object.singleton_methods + base_object.singleton_class.private_instance_methods(false)).include?(method_name.to_sym) && base_object.method(method_name).parameters == SPY_METHOD_PARAMS
          base_object.send(method_name, SECRET_SPY_KEY)
        end
      end

      def get_spies(base_object)
        base_object.singleton_methods.map do |method_name|
          if base_object.method(method_name).parameters == SPY_METHOD_PARAMS
            base_object.send(method_name, SECRET_SPY_KEY)
          end
        end.compact
      end
    end
  end
end
