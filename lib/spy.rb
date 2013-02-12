require "spy/version"
require "spy/double"
require "spy/dsl"
require "spy/core_ext/marshal"

class Spy
  SECRET_SPY_KEY = Object.new
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

    if original_method && original_method.owner == base_object.singleton_class
      base_object.singleton_class.send(:remove_method, method_name)
    end

    __method_spy__ = self
    base_object.define_singleton_method(method_name) do |*__spy_args, &block|
      if __spy_args.first === __method_spy__.class::SECRET_SPY_KEY
        __method_spy__
      else
        __method_spy__.record(self,__spy_args,block)
      end
    end

    base_object.singleton_class.send(opts[:visibility], method_name) if opts[:visibility]

    self.class.all << self
    @was_hooked = true
    self
  end

  # unhooks method from object
  # @return self
  def unhook
    raise "#{method_name} method has not been hooked" unless hooked?
    base_object.singleton_class.send(:remove_method, method_name)
    if original_method && original_method.owner == base_object.singleton_class
      base_object.define_singleton_method(method_name, original_method)
      base_object.singleton_class.send(method_visibility, method_name) if method_visibility
    end
    clear_method!
    self.class.all.delete(self)
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

  # record that the method has been called. You really shouldn't use this
  # method.
  def record(object, args, block)
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

    # create a spy on given object
    # @params base_object
    # @params *method_names [Symbol] will spy on these methods
    # @params *method_names [Hash] will spy on these methods and also set default return values
    # @return [Spy, Array<Spy>]
    def on(base_object, *method_names)
      spies = method_names.map do |method_name|
        create_and_hook_spy(base_object, method_name)
      end.flatten

      spies.size > 1 ? spies : spies.first
    end

    # removes the spy from the from the given object
    # @params base_object
    # @params *method_names
    # @return [Spy, Array<Spy>]
    def off(base_object, *method_names)
      removed_spies = method_names.map do |method_name|
        spies = unhook_and_remove_spy(base_object, method_name)
        raise "No spies found for #{method_name} on #{base_object.inspect}" if spies.empty?
        spies
      end.flatten

      removed_spies.size > 1 ? removed_spies : removed_spies.first
    end

    # get all hooked methods
    # @return [Array<Spy>]
    def all
      @all ||= []
    end

    # unhook all methods
    def teardown
      all.each(&:unhook)
      reset
    end

    # reset all hooked methods
    def reset
      @all = nil
    end

    # (see Double#new)
    def double(*args)
      Double.new(*args)
    end

    # retrieve the spy from an object
    # @params base_object
    # @method_names *[Symbol, Hash]
    def get(base_object, *method_names)
      spies = method_names.map do |method_name|
        if (base_object.singleton_methods + base_object.singleton_class.private_instance_methods(false)).include?(method_name.to_sym) && base_object.method(method_name).parameters == SPY_METHOD_PARAMS
          base_object.send(method_name, SECRET_SPY_KEY)
        end
      end

      spies.size > 1 ? spies : spies.first
    end

    SPY_METHOD_PARAMS = [[:rest, :__spy_args], [:block, :block]]

    def get_spies(base_object)
      base_object.singleton_methods.map do |method_name|
        if base_object.method(method_name).parameters == SPY_METHOD_PARAMS
          base_object.send(method_name, SECRET_SPY_KEY)
        end
      end.compact
    end

    private

    def create_and_hook_spy(base_object, method_name, opts = {})
      case method_name
      when String, Symbol
        new(base_object, method_name).hook(opts)
      when Hash
        method_name.map do |name, result|
          create_and_hook_spy(base_object, name, opts).and_return(result)
        end
      else
        raise ArgumentError.new "#{method_name.class} is an invalid input, #on only accepts String, Symbol, and Hash"
      end
    end

    def unhook_and_remove_spy(base_object, method_name)
      removed_spies = []
      all.each do |spy|
        if spy.base_object == base_object && spy.method_name == method_name
          removed_spies << spy.unhook
        end
      end
      removed_spies
    end
  end
end
