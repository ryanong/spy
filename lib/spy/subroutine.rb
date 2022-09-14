module Spy
  class Subroutine
    include Base
    # @!attribute [r] base_object
    #   @return [Object] the object that is being watched
    #
    # @!attribute [r] method_name
    #   @return [Symbol] the name of the method that is being watched
    #
    # @!attribute [r] singleton_method
    #   @return [Boolean] if the spied method is a singleton_method or not
    #
    # @!attribute [r] calls
    #   @return [Array<CallLog>] the messages that have been sent to the method
    #
    # @!attribute [r] original_method
    #   @return [Method] the original method that was hooked if it existed
    #
    # @!attribute [r] original_method_visibility
    #   @return [Method] the original visibility of the method that was hooked if it existed
    #
    # @!attribute [r] hook_opts
    #   @return [Hash] the options that were sent when it was hooked


    attr_reader :base_object, :method_name, :singleton_method, :calls, :original_method, :original_method_visibility, :hook_opts

    # set what object and method the spy should watch
    # @param object
    # @param method_name <Symbol>
    # @param singleton_method <Boolean> spy on the singleton method or the normal method
    def initialize(object, method_name, singleton_method = true)
      @base_object, @method_name = object, method_name
      @singleton_method = singleton_method
      @plan = nil
      @call_through = false
      reset!
    end

    # hooks the method into the object and stashes original method if it exists
    # @param [Hash] opts what do do when hooking into a method
    # @option opts [Boolean] force (false) if set to true will hook the method even if it doesn't exist
    # @option opts [Symbol<:public, :protected, :private>] visibility overrides visibility with whatever method is given
    # @return [self]
    def hook(opts = {})
      raise AlreadyHookedError, "#{base_object} method '#{method_name}' has already been hooked" if self.class.get(base_object, method_name, singleton_method)

      @hook_opts = opts
      @original_method_visibility = method_visibility_of(method_name)
      hook_opts[:visibility] ||= original_method_visibility

      if original_method_visibility || !hook_opts[:force]
        @original_method = current_method
      end

      if original_method && original_method.owner == base_object
        original_method.owner.send(:remove_method, method_name)
      end

      if singleton_method
        if base_object.singleton_class.method_defined?(method_name) || base_object.singleton_class.private_method_defined?(method_name)
          base_object.singleton_class.send(:alias_method, method_name, method_name)
        end
        base_object.define_singleton_method(method_name, override_method)
      else
        if base_object.method_defined?(method_name) || base_object.private_method_defined?(method_name)
          base_object.send(:alias_method, method_name, method_name)
        end
        base_object.send(:define_method, method_name, override_method)
      end

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
      raise NeverHookedError, "'#{method_name}' method has not been hooked" unless hooked?

      method_owner.send(:remove_method, method_name)
      if original_method && method_owner == original_method.owner
        original_method.owner.send(:define_method, method_name, original_method)
        original_method.owner.send(original_method_visibility, method_name) if original_method_visibility
      end

      clear_method!
      Agency.instance.retire(self)
      self
    end

    # is the spy hooked?
    # @return [Boolean]
    def hooked?
      self == self.class.get(base_object, method_name, singleton_method)
    end

    # @overload and_return(value)
    # @overload and_return(&block)
    #
    # Tells the spy to return a value when the method is called.
    #
    # If a block is sent it will execute the block when the method is called.
    # The airty of the block will be checked against the original method when
    # you first call `and_return` and when the method is called.
    #
    # If you want to disable the arity checking just pass `{force: true}` to the
    # value
    #
    # @example
    #   spy.and_return(true)
    #   spy.and_return { true }
    #   spy.and_return(force: true) { |invalid_arity| true }
    #
    # @return [self]
    def and_return(value = nil, &block)
      @do_not_check_plan_arity = false

      if block_given?
        if value.is_a?(Hash) && value.has_key?(:force)
          @do_not_check_plan_arity = !!value[:force]
        elsif !value.nil?
          raise ArgumentError, "value and block conflict. Choose one"
        end

        @plan = block
        check_for_too_many_arguments!(@plan)
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
      @call_through = true

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
      self
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
      raise NeverHookedError unless @was_hooked
      calls.size > 0
    end

    # check if the method was called with the exact arguments
    # @param args Arguments that should have been sent to the method
    # @return [Boolean]
    def has_been_called_with?(*args, &block)
      raise NeverHookedError unless @was_hooked
      match = block_given? ? block : proc { |call| call.args == args }
      calls.any?(&match)
    end

    # invoke that the method has been called. You really shouldn't use this
    # method.
    def invoke(object, args, block, called_from)
      check_arity!(args.size)

      result =
        if @call_through
          call_plan(build_call_through_plan(object), block, *args)
        elsif @plan
          check_for_too_many_arguments!(@plan)
          call_plan(@plan, block, *args)
        end
    ensure
      calls << CallLog.new(object, called_from, args, block, result)
    end

    # reset the call log
    def reset!
      @was_hooked = false
      @calls = []
      clear_method!
      true
    end

    private

    # this returns a lambda that calls the spy object.
    # we use eval to set the spy object id as a parameter so it can be extracted
    # and looked up later using `Method#parameters`
    SPY_ARGS_PREFIX='__spy_args_'.freeze
    def override_method
      eval <<-METHOD, binding, __FILE__, __LINE__ + 1
      __method_spy__ = self
      lambda do |*#{SPY_ARGS_PREFIX}#{self.object_id}, &block|
        __method_spy__.invoke(self, #{SPY_ARGS_PREFIX}#{self.object_id}, block, caller(1)[0])
      end
      METHOD
    end

    def clear_method!
      @hooked = @do_not_check_plan_arity = false
      @hook_opts = @original_method = @arity_range = @original_method_visibility = @method_owner= nil
    end

    def method_visibility_of(method_name, all = true)
      if singleton_method
        if base_object.public_methods(all).include?(method_name)
          :public
        elsif base_object.protected_methods(all).include?(method_name)
          :protected
        elsif base_object.private_methods(all).include?(method_name)
          :private
        end
      else
        if base_object.public_instance_methods(all).include?(method_name)
          :public
        elsif base_object.protected_instance_methods(all).include?(method_name)
          :protected
        elsif base_object.private_instance_methods(all).include?(method_name)
          :private
        end
      end
    end

    def check_arity!(arity)
      return unless arity_range
      if arity < arity_range.min
        raise ArgumentError.new("wrong number of arguments (#{arity} for #{arity_range.min})")
      elsif arity > arity_range.max
        raise ArgumentError.new("wrong number of arguments (#{arity} for #{arity_range.max})")
      end
      true
    end

    def check_for_too_many_arguments!(block)
      return if @do_not_check_plan_arity || arity_range.nil?
      min_arity = block.arity
      min_arity = min_arity.abs - 1 if min_arity < 0

      min_arity -=1 if base_object.is_a? Class # Instance-method procs take an extra param for receiving object

      if min_arity > arity_range.max
        raise ArgumentError.new("block requires #{min_arity} arguments while original_method require a maximum of #{arity_range.max}")
      end
    end

    def arity_range
      @arity_range ||=
        if original_method
          min = max = 0
          key_args = false
          opt_keys = false
          original_method.parameters.each do |type,_|
            case type
            when :req
              min += 1
              max += 1
            when :opt
              max += 1
            when :rest
              max = Float::INFINITY
            when :keyreq
              key_args = true
            when :keyrest, :key
              key_args = true
              opt_keys = true
            end
          end
          if key_args
            max += 1
            min += 1 unless opt_keys
          end
          (min..max)
        end
    end

    def current_method
      singleton_method ? base_object.method(method_name) : base_object.instance_method(method_name)
    end

    def method_owner
      @method_owner ||= current_method.owner
    end

    def build_call_through_plan(object)
      if original_method
        if @base_object.is_a?(Class) && original_method.is_a?(UnboundMethod)
          original_method.bind(object)
        else
          original_method
        end
      else
        Proc.new do |*args, &block|
          base_object.send(:method_missing, method_name, *args, &block)
        end
      end
    end

    def call_plan(plan, block, *args)
      if ruby_27_last_arg_hash?(args)
        *prefix, last = args
        plan.call(*prefix, **last, &block)
      else
        plan.call(*args, &block)
      end
    end

    # Ruby 2.7 gives a deprecation warning about passing hash as last argument for a method
    # with a double-splat operator (**), and Ruby 3 raises an ArgumentError exception.
    # This checks if args has a hash as last element to extract it and pass it with double-splat to avoid an exception.
    def ruby_27_last_arg_hash?(args)
      last = args.last
      last.instance_of?(Hash) &&
        !last.empty? &&
        Gem::Version.new(RUBY_VERSION) >= Gem::Version.new("2.7.0")
    end

    class << self

      # retrieve the method spy from an object or create a new one
      # @param base_object
      # @param method_name [Symbol]
      # @param singleton_method [Boolean] this a singleton method or a instance method?
      # @return [Array<Subroutine>]
      def on(base_object, method_name, singleton_method = true)
        new(base_object, method_name, singleton_method).hook
      end

      def off(base_object, method_name, singleton_method = true)
        spy = get(base_object, method_name, singleton_method = true)
        raise NoSpyError, "#{method_name} was not spied on #{base_object}" unless spy
        spy.unhook
      end

      # retrieve the method spy from an object or return nil
      # @param base_object
      # @param method_name [Symbol]
      # @param singleton_method [Boolean] this a singleton method or a instance method?
      # @return [Array<Subroutine>]
      def get(base_object, method_name, singleton_method = true)
        if singleton_method
          if base_object.respond_to?(method_name, true)
            spied_method = base_object.method(method_name)
          end
        elsif (base_object.public_instance_methods +
               base_object.protected_instance_methods +
               base_object.private_instance_methods).include?(method_name)
          spied_method = base_object.instance_method(method_name)
        end

        if spied_method
          Agency.instance.find(get_spy_id(spied_method))
        end
      end

      # retrieve all the spies from a given object
      # @param base_object
      # @param singleton_method [Boolean] (true) only get singleton_method_spies
      # @return [Array<Subroutine>]
      def get_spies(base_object, singleton_methods = true)
        all_methods =
          if singleton_methods
            base_object.public_methods(false) +
              base_object.protected_methods(false) +
              base_object.private_methods(false)
          else
            base_object.public_instance_methods(false) +
              base_object.protected_instance_methods(false) +
              base_object.private_instance_methods(false)
          end

        all_methods.map do |method_name|
          Agency.instance.find(get_spy_id(base_object.method(method_name)))
        end.compact
      end

      # @private
      def get_spy_id(method)
        if method.parameters[0].is_a?(Array) && method.parameters[0][1]
          raw_id = method.parameters[0][1].to_s
          if raw_id.start_with?(SPY_ARGS_PREFIX)
            raw_id[SPY_ARGS_PREFIX.length..-1].to_i
          end
        end
      end
    end
  end
end
