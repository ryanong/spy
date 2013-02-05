require "spy/version"
require "spy/double"
require "spy/dsl"

class Spy
  CallLog = Struct.new(:object, :args, :block)

  attr_reader :base_object, :method_name, :calls
  def initialize(object, method_name)
    @base_object, @method_name = object, method_name
    reset!
  end

  def hook(opts = {})
    raise "#{method_name} method has already been hooked" if hooked?
    opts[:force] ||= base_object.is_a?(Double)
    if base_object.respond_to?(method_name, true) || !opts[:force]
      @original_method = base_object.method(method_name)
    end

    opts[:visibility] ||= method_visibility

    if original_method && original_method.owner == base_object.singleton_class
      base_object.singleton_class.send(:remove_method, method_name)
    end

    __method_spy__ = self
    base_object.define_singleton_method(method_name) do |*args, &block|
      if args.first === __method_spy__.class.__secret_method_key__
        __method_spy__
      else
        __method_spy__.record(self,args,block)
      end
    end

    base_object.singleton_class.send(opts[:visibility], method_name) if opts[:visibility]
    @hooked = true
    self
  end

  def unhook
    raise "#{method_name} method has not been hooked" unless hooked?
    base_object.singleton_class.send(:remove_method, method_name)
    if original_method && original_method.owner == base_object.singleton_class
      base_object.define_singleton_method(method_name, original_method)
      base_object.singleton_class.send(method_visibility, method_name) if method_visibility
    end
    clear_method!
    self
  end

  def hooked?
    @hooked
  end

  def and_return(value = nil, &block)
    if block_given?
      raise ArgumentError.new("value and block conflict. Choose one") if !value.nil?
      @plan = block
    else
      @plan = Proc.new { value }
    end
    self
  end

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
    calls.size > 0
  end

  def has_been_called_with?(*args)
    calls.any? do |call_log|
      call_log.args == args
    end
  end

  def record(object, args, block)
    check_arity!(args.size)
    calls << CallLog.new(object, args, block)
    @plan.call(*args, &block) if @plan
  end

  def reset!
    @calls = []
    clear_method!
    true
  end

  private
  attr_reader :original_method

  def clear_method!
    @hooked = false
    @original_method = @arity_range = @method_visibility = nil
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
    return unless arity_range
    if arity < arity_range.min
      raise ArgumentError.new("wrong number of arguments (#{arity} for #{arity_range.min})")
    elsif arity > arity_range.max
      raise ArgumentError.new("wrong number of arguments (#{arity} for #{arity_range.max})")
    end
  end

  def arity_range
    @arity_range ||=
      if original_method
        min = max = 0
        original_method.parameters.each do |type,_|
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
  end

  class << self
    def on(base_object, *method_names)
      spies = method_names.map do |method_name|
        create_and_hook_spy(base_object, method_name)
      end.flatten

      spies.one? ? spies.first : spies
    end

    def off(base_object, *method_names)
      removed_spies = method_names.map do |method_name|
        unhook_and_remove_spy(base_object, method_name)
      end.flatten

      raise "No spies found" if removed_spies.empty?
      removed_spies.one? ? removed_spies.first : removed_spies
    end

    def all
      @all ||= []
    end

    def teardown
      all.each(&:unhook)
      reset
    end

    def reset
      @all = nil
    end

    def double(*args)
      Double.new(*args)
    end

    def __secret_method_key__
      @__secret_method_key__ ||= Object.new
    end

    def get(base_object, *method_names)
      spies = method_names.map do |method_name|
        base_object.send(method_name, __secret_method_key__)
      end

      spies.one? ? spies.first : spies
    end

    private

    def create_and_hook_spy(base_object, method_name, opts = {})
      case method_name
      when String, Symbol
        spy = new(base_object, method_name).hook(opts)
        all << spy
        spy
      when Hash
        method_name.map do |name, result|
          create_and_hook_spy(base_object, name, opts).and_return(result)
        end
      else
        raise ArgumentError.new "#{method_name.class} is an invalid class, #on only accepts String, Symbol, and Hash"
      end
    end

    def unhook_and_remove_spy(base_object, method_name)
      removed_spies = []
      all.delete_if do |spy|
        if spy.base_object == base_object && spy.method_name == method_name
          removed_spies << spy.unhook
        end
      end
      removed_spies
    end
  end
end
