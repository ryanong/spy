module Spy
  # A Mock is an object that has all the same methods as the given class.
  # Each method however will raise a NeverHookedError if it hasn't been stubbed.
  # If you attempt to stub a method on the mock that doesn't exist on the
  # original class it will raise an error.
  module Mock
    CLASSES_NOT_TO_OVERRIDE = [Enumerable, Numeric, Comparable, Class, Module, Object]

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

      def new(klass)
        mock_klass = Class.new(klass)
        mock_klass.class_exec do
          alias :_mock_class :class
          private :_mock_class

          define_method(:class) do
            klass
          end

          include Mock
        end
        mock_klass
      end

      def included(mod)
        method_classes = classes_to_override_methods(mod)

        [:public, :protected, :private].each do |visibility|
          get_inherited_methods(method_classes, visibility).each do |method_name|
            args = args_for_method(mod.instance_method(method_name))

            mod.class_eval <<-DEF_METHOD, __FILE__, __LINE__+1
              def #{method_name}(#{args})
                raise ::Spy::NeverHookedError, "'#{method_name}' was never hooked on mock spy."
              end

              #{visibility} :#{method_name}
            DEF_METHOD
          end
        end
      end

      private

      def classes_to_override_methods(mod)
        method_classes = mod.ancestors
        method_classes.shift
        method_classes.delete(self)
        CLASSES_NOT_TO_OVERRIDE.each do |klass|
          index = method_classes.index(klass)
          method_classes.slice!(index..-1) if index
        end
        method_classes
      end

      def get_inherited_methods(klass_ancestors, visibility)
        get_methods_method = "#{visibility}_instance_methods".to_sym
        instance_methods = klass_ancestors.map(&get_methods_method)
        instance_methods.flatten!
        instance_methods.uniq!
        instance_methods - Object.send(get_methods_method)
      end

      def args_for_method(method)
        args = method.parameters.map do |type,name|
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
        args << "&never_hooked"
        args.join(",")
      end
    end
  end
end
