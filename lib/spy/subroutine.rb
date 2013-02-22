module Spy
  class Subroutine
    CallLog = Struct.new(:object, :called_from, :args, :block, :result)

    # @!attribute [r] base_object
    #   @return [Object] the object that is being watched
    #
    # @!attribute [r] method_name
    #   @return [Symbol] the name of the method that is being watched
    #
    # @!attribute [r] calls
    #   @return [Array<CallLog>] the messages that have been sent to the method
    #
    # @!attribute [r] original_method
    #   @return [Method] the original method that was hooked if it existed
    #
    # @!attribute [r] hook_opts
    #   @return [Hash] the options that were sent when it was hooked


    attr_reader :base_object, :method_name, :calls, :original_method, :hook_opts

    # set what object and method the spy should watch
    # @param object
    # @param method_name <Symbol>
    # @param singleton_method <Boolean> spy on the singleton method or the normal method
    def initialize(object, method_name, singleton_method = true)
      @base_object, @method_name = object, method_name
      @singleton_method = singleton_method
      reset!
    end

    # hooks the method into the object and stashes original method if it exists
    # @param [Hash] opts what do do when hooking into a method
    # @option opts [Boolean] force (false) if set to true will hook the method even if it doesn't exist
    # @option opts [Symbol<:public, :protected, :private>] visibility overrides visibility with whatever method is given
    # @return [self]
    def hook(opts = {})
      @hook_opts = opts
      raise "#{base_object} method '#{method_name}' has already been hooked" if hooked?

      hook_opts[:force] ||= base_object.is_a?(Double)
      if (base_object_respond_to?(method_name, true)) || !hook_opts[:force]
        @original_method = current_method
      end
      hook_opts[:visibility] ||= method_visibility

      base_object.send(define_method_with, method_name, override_method)

      if [:public, :protected, :private].include? hook_opts[:visibility]
        method_owner.send(hook_opts[:visibility], method_name)
      end

      Agency.instance.recruit(self)
      @was_hooked = true
      self
    end

    # unhooks method from object
    # @return [self]
    def unhook
      raise "'#{method_name}' method has not been hooked" unless hooked?

      if original_method && method_owner == original_method.owner
        original_method.owner.send(:define_method, method_name, original_method)
        original_method.owner.send(method_visibility, method_name) if method_visibility
      else
        method_owner.send(:remove_method, method_name)
      end
      clear_method!
      Agency.instance.retire(self)
      self
    end

    # is the spy hooked?
    # @return [Boolean]
    def hooked?
      self == self.class.get(base_object, method_name, @singleton_method)
    end

    # @overload and_return(value)
    # @overload and_return(&block)
    #
    # Tells the spy to return a value when the method is called.
    #
    # @return [self]
    def and_return(value = nil)
      if block_given?
        @plan = Proc.new
        if value.nil? || value.is_a?(Hash) && value.has_key?(:force)
          if !(value.is_a?(Hash) && value[:force]) &&
              original_method &&
              original_method.arity >=0 &&
              @plan.arity > original_method.arity
            raise ArgumentError.new "The original method only has an arity of #{original_method.arity} you have an arity of #{@plan.arity}"
          end
        else
          raise ArgumentError.new("value and block conflict. Choose one") if !value.nil?
        end
      else
        @plan = Proc.new { value }
      end
      self
    end

    # Tells the object to yield one or more args to a block when the message is received.
    # @return [self]
    def and_yield(*args)
      yield eval_context = Object.new if block_given?
      @plan = Proc.new do |&block|
        eval_context.instance_exec(*args, &block)
      end
      self
    end

    # tells the spy to call the original method
    # @return [self]
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

    # @overload and_raise
    # @overload and_raise(ExceptionClass)
    # @overload and_raise(ExceptionClass, message)
    # @overload and_raise(exception_instance)
    #
    # Tells the object to raise an exception when the message is received.
    #
    # @note
    #
    #   When you pass an exception class, the MessageExpectation will raise
    #   an instance of it, creating it with `exception` and passing `message`
    #   if specified.  If the exception class initializer requires more than
    #   one parameters, you must pass in an instance and not the class,
    #   otherwise this method will raise an ArgumentError exception.
    #
    # @return [self]
    def and_raise(exception = RuntimeError, message = nil)
      if exception.respond_to?(:exception)
        exception = message ? exception.exception(message) : exception.exception
      end

      @plan = Proc.new { raise exception }
    end

    # @overload and_throw(symbol)
    # @overload and_throw(symbol, object)
    #
    # Tells the object to throw a symbol (with the object if that form is
    # used) when the message is received.
    #
    # @return [self]
    def and_throw(*args)
      @plan = Proc.new { throw(*args) }
      self
    end

    # if the method was called it will return true
    # @return [Boolean]
    def has_been_called?
      raise "was never hooked" unless @was_hooked
      calls.size > 0
    end

    # check if the method was called with the exact arguments
    # @param args Arguments that should have been sent to the method
    # @return [Boolean]
    def has_been_called_with?(*args)
      raise "was never hooked" unless @was_hooked
      calls.any? do |call_log|
        call_log.args == args
      end
    end

    # invoke that the method has been called. You really shouldn't use this
    # method.
    def invoke(object, args, block, called_from)
      check_arity!(args.size)
      result = @plan ? @plan.call(*args, &block) : nil
    ensure
      calls << CallLog.new(object,called_from, args, block, result)
    end

    # reset the call log
    def reset!
      @was_hooked = false
      @calls = []
      clear_method!
      true
    end

    private

    def override_method
      eval <<-METHOD, binding, __FILE__, __LINE__ + 1
      __method_spy__ = self
      lambda do |*__spy_args_#{self.object_id}, &block|
        __method_spy__.invoke(self, __spy_args_#{self.object_id}, block, caller(1)[0])
      end
      METHOD
    end

    def call_with_yield(&block)
      raise "no block sent" unless block
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
      @hook_opts = @original_method = @arity_range = @method_visibility = @method_owner= nil
    end

    def method_visibility
      @method_visibility ||=
        if base_object_respond_to?(method_name)
          if original_method && original_method.owner.protected_method_defined?(method_name)
            :protected
          else
            :public
          end
        elsif base_object_respond_to?(method_name, true)
          :private
        end
    end

    def base_object_respond_to?(method_name, include_private = false)
      if @singleton_method
        base_object.respond_to?(method_name, include_private)
      else
        base_object.instance_methods.include?(method_name) || (
          include_private && base_object.private_instance_methods.include?(method_name)
        )
      end
    end

    def define_method_with
      @singleton_method ? :define_singleton_method : :define_method
    end

    def check_arity!(arity)
      self.class.check_arity_against_range!(arity_range, arity)
    end

    def arity_range
      @arity_range ||= self.class.arity_range_of(original_method) if original_method
    end

    def current_method
      @singleton_method ? base_object.method(method_name) : base_object.instance_method(method_name)
    end

    def method_owner
      @method_owner ||= current_method.owner
    end

    class << self
      # @private
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

      # @private
      def check_arity_against_range!(arity_range, arity)
        return unless arity_range
        if arity < arity_range.min
          raise ArgumentError.new("wrong number of arguments (#{arity} for #{arity_range.min})")
        elsif arity > arity_range.max
          raise ArgumentError.new("wrong number of arguments (#{arity} for #{arity_range.max})")
        end
      end

      # retrieve the method spy from an object
      # @param base_object
      # @param method_name [Symbol]
      # @param singleton_method [Boolean] this a singleton method or a instance method?
      # @return [Array<Subroutine>]
      def get(base_object, method_name, singleton_method = true)
        if singleton_method
          if base_object.respond_to?(method_name, true)
            spied_method = base_object.method(method_name)
          end
        elsif (base_object.instance_methods + base_object.private_instance_methods).include?(method_name)
          spied_method = base_object.instance_method(method_name)
        end

        if spied_method
          Agency.instance.find(get_spy_id(spied_method))
        end
      end

      # retrieve all the spies from a given object
      # @param base_object
      # @return [Array<Subroutine>]
      def get_spies(base_object)
        all_methods = base_object.public_methods(false) +
          base_object.protected_methods(false) +
          base_object.private_methods(false)
        all_methods += base_object.instance_methods(false) + base_object.private_instance_methods(false) if base_object.respond_to?(:instance_methods)
        all_methods.map do |method_name|
          Agency.instance.find(get_spy_id(base_object.method(method_name)))
        end.compact
      end

      private

      def get_spy_id(method)
        return nil unless method.parameters[0].is_a?(Array)
        first_param_name = method.parameters[0][1].to_s
        if first_param_name.include?("__spy_args")
          first_param_name.split("_").last.to_i
        end
      end
    end
  end
end
