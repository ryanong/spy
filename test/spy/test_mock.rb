require 'test_helper'

module Spy
  class TestMock < Minitest::Test
    class BluePen < Pen
      def write_hello(other)
      end
    end

    def setup
      @pen_mock = Mock.new(BluePen)
      @pen = @pen_mock.new
    end

    def teardown
      Spy::Agency.instance.dissolve!
    end

    def test_class_methods
      assert @pen.kind_of?(BluePen)
      assert @pen.kind_of?(Pen)
      assert @pen.is_a?(Pen)
      assert @pen.is_a?(BluePen)
      assert @pen.instance_of?(BluePen)
      assert_equal BluePen, @pen.class
    end

    def test_raises_error_on_unstubbed_method
      assert_raises Spy::NeverHookedError do
        @pen.write("")
      end
    end

    def test_mimics_visibility
      assert @pen.singleton_class.public_method_defined? :public_method
      assert @pen.singleton_class.protected_method_defined? :protected_method
      assert @pen.singleton_class.private_method_defined? :private_method
    end

    def test_that_method_spy_keeps_arity
      assert_raises ArgumentError do
        @pen.write
      end

      assert_raises ArgumentError do
        @pen.write("hello", "world")
      end

      assert_raises ArgumentError do
        @pen.write_hello
      end

      assert_raises ArgumentError do
        @pen.greet
      end

      assert_raises ArgumentError do
        @pen.greet("hello", "bob", "error")
      end
    end

    def test_that_and_call_original_works
      Spy.on(@pen, :another).and_call_through
      assert_equal "another", @pen.another
      Spy.off(@pen, :another)
      assert_raises Spy::NeverHookedError do
        @pen.another
      end
    end

    def test_mocked_methods
      pen_methods = Pen.public_instance_methods(false) +
        Pen.protected_instance_methods(false) +
        Pen.private_instance_methods(false)
      pen_methods.delete(:initialize)
      assert_equal pen_methods.sort, @pen_mock.mocked_methods.sort
    end

    buggy_methods = [:tap, :pretty_print_inspect]
    methods_to_test = Object.instance_methods - buggy_methods
    methods_to_test.each do |method_name|
      object_method = Object.instance_method(method_name)
      if object_method.arity == 0 || (RUBY_ENGINE != "jruby" && object_method.parameters == [])
        define_method("test_base_class_method_#{method_name}_is_not_stubbed") do
          @pen_mock.new.send(method_name)
        end
      end
    end
  end
end
