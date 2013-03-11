module Spy
  # A Mock is an object that has all the same methods as the given class.
  # Each method however will raise a NeverHookedError if it hasn't been stubbed.
  # If you attempt to stub a method on the mock that doesn't exist on the
  # original class it will raise an error.
  class Mock
    # @param klass [Class] the Class you with the Mock to mock.
    def initialize(klass)
      @klass = klass
      method_ancestors = klass.ancestors
      method_ancestors.slice!(method_ancestors.index(Object)..-1)
      [:public, :protected, :private].each do |visibility|
        Mock.get_inherited_methods(method_ancestors, visibility).each do |method_name|
          method_args = Mock.parameters_to_args(klass.instance_method(method_name).parameters)
          singleton_class.class_eval <<-DEF_METHOD, __FILE__, __LINE__ + 1
            def #{method_name}(#{method_args})
              raise ::Spy::NeverHookedError, "'#{method_name}' was never hooked on mock spy"
            end
          DEF_METHOD
          singleton_class.send(visibility, method_name)
        end
      end
    end

    # @return [Boolean]
    def is_a?(other)
      @klass.ancestors.include?(other)
    end

    # @return [Boolean]
    def kind_of?(other)
      @klass.ancestors.include?(other)
    end

    # @return [Boolean]
    def instance_of?(other)
      other == @klass
    end

    # returns the class that was given during initialization
    # @returns [Class]
    def class
      @klass
    end

    class << self
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
        end.compact.join(',')
      end

    end
  end
end
