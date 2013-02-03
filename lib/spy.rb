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
    opts[:force] ||= base_object.kind_of?(Double)
    if method_visibility || !opts[:force]
      @original_method = base_object.method(method_name)
      if base_object.singleton_methods.include?(method_name)
        base_object.singleton_class.send(:remove_method, method_name)
      end
    end

    __spies_spy = self
    base_object.define_singleton_method(method_name) do |*args, &block|
      __spies_spy.record(self,args,block)
    end

    opts[:visibility] ||= method_visibility
    base_object.singleton_class.send(opts[:visibility], method_name) if opts[:visibility]
    @hooked = true
    self
  end

  def unhook
    raise "#{method_name} method has not been hooked" unless hooked?
    base_object.singleton_class.send(:remove_method, method_name)
    base_object.define_singleton_method(method_name, original_method) if original_method
    base_object.singleton_class.send(method_visibility, method_name) if method_visibility
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
    raise "can only call through if original method is set" unless original_method
    @plan = original_method
  end

  def called?
    calls.size > 0
  end

  def called_with?(*args)
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
    @original_method = @arity_range = @method_visiblity = nil
  end

  def method_visibility
    @method_visibility ||=
      if base_object.class.public_method_defined? method_name
        :public
      elsif base_object.class.protected_method_defined? method_name
        :protected
      elsif base_object.class.private_method_defined? method_name
        :private
      else
        nil
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
    def on(base_object, method_name, *args)
      case method_name
      when String, Symbol
        spy = new(base_object, method_name).hook
        all << spy
        spies = [spy]
      when Hash
        spies = arg.map do |name, result|
          on(base_object, name).and_return(result)
        end
      else
        raise ArgumentError.new "#{method_name.class} is an invalid class, #on only accepts String, Symbol, and Hash"
      end

      spies += args.map do |arg|
        on(base_object, arg)
      end.flatten

      if spies.size == 1
        spies.first
      else
        spies
      end
    end

    def off(base_object, method_name, *args)
      removed_spies = []
      all.delete_if do |spy|
        if spy.base_object == base_object && spy.method_name == method_name
          spy.unhook
          removed_spies << spy
        end
      end

      removed_spies + args.map do |arg|
        off(base_object, arg)
      end.flatten
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
  end
end
