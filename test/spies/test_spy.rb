require 'test_helper'

module Spies
  class TestSpy < MiniTest::Unit::TestCase
    class Pen
      attr_reader :written

      def initialize
        @written = []
      end

      def write(string)
        @written << string
        string
      end

      def write_block(&block)
        string = yield
        @written << string
        string
      end

      def write_hello
        write("hello")
      end

      def write_array(*args)
        args.each do |arg|
          write(arg)
        end
      end

      def greet(hello = "hello", name)
        write("#{hello} #{name}")
      end

      def public_method
      end

      protected
      def protected_method
      end

      private
      def private_method
      end
    end

    def setup
      @pen = Pen.new
    end

    def teardown
      Spy.reset
    end

    def test_spy_on_hook_and_saves_spy
      pen_write_spy = Spy.on(@pen, :write)
      assert_kind_of Spy, pen_write_spy
      assert_equal Spy.all, [pen_write_spy]
    end

    def test_spy_can_hook_and_record_a_method_call
      pen_write_spy = Spy.new(@pen, :write)
      pen_write_spy.hook
      refute pen_write_spy.called?
      @pen.write("hello")
      assert pen_write_spy.called?
      assert_empty @pen.written
    end

    def test_spy_can_unhook_a_method
      pen_write_spy = Spy.new(@pen, :write)
      pen_write_spy.hook
      pen_write_spy.unhook
      @pen.write("hello")
      refute pen_write_spy.called?
    end

    def test_spy_cannot_hook_a_non_existent_method
      spy = Spy.new(@pen, :no_method)
      assert_raises NameError do
        spy.hook
      end
    end

    def test_spy_can_hook_a_non_existent_method_if_param_set
      spy = Spy.new(@pen, :no_method).and_return(:yep)
      spy.hook(force: true)
      assert_equal :yep, @pen.no_method
    end

    def test_spy_and_return_returns_the_set_value
      result = "hello world"

      Spy.on(@pen, :write).and_return(result)

      assert_equal result, @pen.write(nil)
    end

    def test_spy_and_return_can_call_a_block
      result = "hello world"

      Spy.on(@pen, :write).and_return do |string|
        string.reverse
      end

      assert_equal result.reverse, @pen.write(result)
      assert_empty @pen.written
    end

    def test_spy_and_return_can_call_a_block_that_recieves_a_block
      string = "hello world"

      Spy.on(@pen, :write_block).and_return do |&block|
        block.call
      end

      result = @pen.write_block do
        string
      end
      assert_equal string, result
    end

    def test_spy_hook_records_number_of_calls
      pen_write_spy = Spy.on(@pen, :write)
      assert_equal 0, pen_write_spy.calls.size
      5.times do |i|
        @pen.write("hello world")
        assert_equal i + 1, pen_write_spy.calls.size
      end
    end

    def test_called_with?
      pen_write_spy = Spy.on(@pen, :write)
      refute pen_write_spy.called_with?("hello")
      @pen.write("hello")
      assert pen_write_spy.called_with?("hello")
      @pen.write("world")
      assert pen_write_spy.called_with?("hello")
      @pen.write("hello world")
      assert pen_write_spy.called_with?("hello")
    end

    def test_spy_hook_records_number_of_calls
      args = ["hello world"]
      block = Proc.new {}
      pen_write_spy = Spy.on(@pen, :write)
      @pen.write(*args, &block)
      call_log = pen_write_spy.calls.first
      assert_equal @pen, call_log.object
      assert_equal args, call_log.args
      assert_equal block, call_log.block
    end

    def test_that_method_spy_keeps_arity
      Spy.on(@pen, :write)
      @pen.write("hello world")
      assert_raises ArgumentError do
        @pen.write("hello", "world")
      end

      Spy.on(@pen, :write_hello)
      @pen.write_hello
      assert_raises ArgumentError do
        @pen.write_hello("hello")
      end

      Spy.on(@pen, :write_array)
      @pen.write_hello
      assert_raises ArgumentError do
        @pen.write_hello("hello")
      end

      Spy.on(@pen, :greet)
      @pen.greet("bob")
      assert_raises ArgumentError do
        @pen.greet
      end
      assert_raises ArgumentError do
        @pen.greet("hello", "bob", "error")
      end
    end

    def test_hook_mimics_method_visibility
      Spy.on(@pen, :public_method)
      assert @pen.singleton_class.public_method_defined? :public_method
      refute @pen.singleton_class.protected_method_defined? :public_method
      refute @pen.singleton_class.private_method_defined? :public_method

      Spy.on(@pen, :protected_method)
      refute @pen.singleton_class.public_method_defined? :protected_method
      assert @pen.singleton_class.protected_method_defined? :protected_method
      refute @pen.singleton_class.private_method_defined? :protected_method

      Spy.on(@pen, :private_method)
      refute @pen.singleton_class.public_method_defined? :private_method
      refute @pen.singleton_class.protected_method_defined? :private_method
      assert @pen.singleton_class.private_method_defined? :private_method
    end

    def test_spy_can_unhook_a_method
      pen_write_spy = Spy.on(@pen, :write)
      Spy.off(@pen,:write)
      assert_equal "hello world", @pen.write("hello world")
      refute pen_write_spy.called?
    end
  end
end
