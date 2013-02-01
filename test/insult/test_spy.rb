require 'test_helper'
require 'stringio'

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

    def test_that_you_cannot_spy_a_non_existent_method
      assert_raises NoMethodError do
        Spy.on(@pen, :no_method)
      end
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

    def test_that_method_call_was_recoreded
      @pen_write_spy = Spy.on(@pen, :write)
      @pen.write("hello world")
      assert @pen_write_spy.was_called?
    end
  end
end
