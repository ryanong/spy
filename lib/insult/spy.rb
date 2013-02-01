module Insult
  class Spy
    attr_reader :base_object

    def initialize(object)
      @base_object = object
      @method_spies = {}
    end

    def watch_method(method_name, ignore_method_doesnt_exist = false)
      method_name = method_name.to_sym
      if !ignore_method_doesnt_exist && !base_object.respond_to?(method_name)
        raise NoMethodError.new("#{base_object.inspect} must have '#{method_name}' as a method")
      end

      if @method_spies[method_name]
        raise NameError.new("#{method_name} already stubbed")
      end

      params = base_object.method(method_name).parameters

      arity = parameters_to_args(params)
      arity << "&block"
      vars = parameters_to_vars(params)

      base_object.singleton_class.class_eval <<-EOF, __FILE__, __LINE__ + 1
        def #{method_name}(#{arity.join(",")})
          ::Insult::Spy.fetch(self).message_received :#{method_name}, [#{vars.join(",")}], &block
        end
      EOF
      @method_spies[method_name] = MethodSpy.new(@base_object, method_name)
    end

    def message_received(method_name, args)
      @method_spies[method_name].called_with(args)
    end

    private

    def parameters_to_args(params)
      params.map do |type,name|
        name ||= :args
        case type
        when :req
          name
        when :opt
          "#{name} = nil"
        when :rest
          "*#{name}"
        end
      end.compact
    end

    def parameters_to_vars(params)
      params.map do |type,name|
        if type != :block
          name ||= :args
        end
      end.compact
    end

    class << self
      def on(object, method_name, ignore_method_doesnt_exit = false)
        if object.nil?
          raise ArgumentError.new("#{object.inspect} must not be nil")
        end

        fetch(object).watch_method(method_name, ignore_method_doesnt_exit)
      end

      def fetch(object)
        object_spy = object.instance_variable_get(:@__spy)
        unless object_spy
          object_spy = new(object)
          spies << object_spy
          object.instance_variable_set(:@__spy, object_spy)
        end
        object_spy
      end

      def spies
        @spies ||= []
      end

      def teardown
        spies.each(&:teardown)
      end
    end
  end
end
