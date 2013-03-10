module Spy
  def mock(klass, *args)
    Mock.new(klass, *args)
  end

  class Mock
    RAISE_NEVER_HOOKED_PROC = Proc.new do
      raise NeverHookedError, "#{method} was never hooked on given mock"
    end

    def initialize(klass, stubs = {})
      @klass = klass
      # method_ancestors = klass.ancestors
      # method_ancestors.slice!(method_ancestors.index(Object)..-1)
      # public_methods = method_ancestors.map(&:public_instance_methods).flatten.uniq
      # public_methods.each do |method|
      #   define_singleton_method(method, RAISE_NEVER_HOOKED_PROC)
      # end

      # protected_methods = method_ancestors.map(&:protected_instance_methods).flatten.uniq
      # protected_methods.each do |method|
      #   define_singleton_method(method, RAISE_NEVER_HOOKED_PROC)

      # end
    end

    def is_a?(other)
      @klass.ancestors.include?(other)
    end

    def kind_of?(other)
      @klass.ancestors.include?(other)
    end

    def instance_of?(other)
      other == @klass
    end

    def class
      @klass
    end
  end
end
