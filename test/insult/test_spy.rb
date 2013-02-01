require 'test_helper'

module Insult
  class TestSpy < MiniTest::Unit::TestCase
    class Pen
      def write(string)
        string
      end

      def write_hello
        "hello"
      end

      def write_array(*args)
        args.join(" ")
      end

      def greet(hello = "hello", name)
        "#{hello} #{name}"
      end

      def write_letter
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
      assert_equal Spy.spies, [pen_write_spy]
    end

    def test_spy_can_hook_and_record_a_method_call
      @pen_write_spy = Spy.new(@pen, :write)
      @pen_write_spy.hook
      refute @pen_write_spy.was_called?
      @pen.write("hello")
      assert @pen_write_spy.was_called?
    end

    def test_spy_can_unhook_a_method
      @pen_write_spy = Spy.new(@pen, :write)
      @pen_write_spy.hook
      @pen_write_spy.unhook
      @pen.write("hello")
      refute @pen_write_spy.was_called?
    end

    def test_spy_cannot_hook_a_non_existent_method
      assert_raises NameError do
        Spy.on(@pen, :no_method)
      end
    end

    def test_spy_hook_records_number_of_calls
      @pen_write_spy = Spy.on(@pen, :write)
      assert_equal 0, @pen_write_spy.calls.size
      5.times do |i|
        @pen.write("hello world")
        assert_equal i + 1, @pen_write_spy.calls.size
      end
    end

    def test_spy_hook_records_number_of_calls
      args = ["hello world"]
      block = Proc.new {}
      @pen_write_spy = Spy.on(@pen, :write)
      @pen.write(*args, &block)
      call_log = @pen_write_spy.calls.first
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

    def test_spy_can_unhook_a_method
      Spy.off(@pen,:method)
      @pen_write_spy = Spy.new(@pen, :write)
      @pen_write_spy.hook
      @pen.write("hello world")
    end
  end
end
