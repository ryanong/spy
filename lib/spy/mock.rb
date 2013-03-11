module Spy
  # A Mock is an object that has all the same methods as the given class.
  # Each method however will raise a NeverHookedError if it hasn't been stubbed.
  # If you attempt to stub a method on the mock that doesn't exist on the
  # original class it will raise an error.
  module Mock
    CLASSES_NOT_TO_OVERRIDE = [Enumerable, Numeric, Comparable, Class, Module, Object, Kernel, BasicObject]

    def initialize
    end

    def is_a?(other)
      self.class.ancestors.include?(other)
    end

    alias :kind_of? :is_a?

    def instance_of?(other)
      other == self.class
    end

    def method(method_name)
      new_method = super
      if new_method.parameters.size >= 1 &&
        new_method.parameters.last.last == :never_hooked

        begin
          _mock_class.send(:remove_method, method_name)
          real_method = super
        ensure
          _mock_class.send(:define_method, method_name, new_method)
        end

        real_method
      else
        new_method
      end
    end

    class << self

      def included(mod)
      end
      def new(klass)
        method_classes = klass.ancestors
        method_classes -= CLASSES_NOT_TO_OVERRIDE
        method_classes << klass
        method_classes.uniq!

        mock_klass = Class.new(klass)
        mock_klass.class_exec do
          include Mock

          alias :_mock_class :class
          private :_mock_class

          define_method(:class) do
            klass
          end

          [:public, :protected, :private].each do |visibility|
            Mock.get_inherited_methods(method_classes, visibility).each do |method_name|
              method_args = Mock.parameters_to_args(klass.instance_method(method_name).parameters)
              method_args << "&never_hooked"

              eval <<-DEF_METHOD, binding, __FILE__, __LINE__+1
                def #{method_name}(#{method_args.join(",")})
                  raise ::Spy::NeverHookedError, "'#{method_name}' was never hooked on mock spy."
                end

                #{visibility} :#{method_name}
              DEF_METHOD
            end
          end
        end
        mock_klass
      end

      def get_inherited_methods(klass_ancestors, visibility)
        get_methods_method = "#{visibility}_instance_methods".to_sym
        instance_methods = klass_ancestors.map(&get_methods_method)
        instance_methods.flatten!
        instance_methods.uniq!
        instance_methods - Object.send(get_methods_method)
      end

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
    end
  end
end
