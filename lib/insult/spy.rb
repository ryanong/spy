module Insult
  class Spy
    CallLog = Struct.new(:object, :args, :block)

    attr_reader :base_object, :method_name
    def initialize(object, method_name)
      @base_object, @method_name = object, method_name
      reset!
    end

    def hook
      raise "#{method_name} has already been hooked" if base_object.singleton_methods.include?(method_name)
      @original_method = base_object.method(method_name)

      __insult_arity_range = get_arity_range(@original_method.parameters)
      __insult_spy = self

      @base_object.define_singleton_method(method_name) do |*args, &block|
        __insult_spy.check_arity!(__insult_arity_range, args.size)
        __insult_spy.called_with(self,args, &block)
      end
    end

    def unhook
      raise "#{method_name} has not been hooked" unless base_object.singleton_methods.include?(method_name)
      @original_method = nil
      @base_object.singleton_class.undef_method method_name
    end

    def was_called?
      @calls.size > 0
    end

    def called_with(object, args, &block)
      @calls << CallLog.new(object, args, block)
      nil
    end

    def reset!
      @calls = []
    end

    def check_arity!(arity_range, arity)
      if arity < arity_range.min
        raise ArgumentError.new("wrong number of arguments (#{arity} for #{arity_range.min})")
      elsif arity > arity_range.max
        raise ArgumentError.new("wrong number of arguments (#{arity} for #{arity_range.max})")
      end
    end

    private

    def get_arity_range(parameters)
      min = 0
      max = 0
      parameters.each do |type,_|
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

    class << self
      def on(base_object, method_name)
        spy = new(base_object, method_name.to_sym).tap(&:hook)
        spies << spy
        spy
      end

      def spies
        @spies ||= []
      end
    end
  end
end
