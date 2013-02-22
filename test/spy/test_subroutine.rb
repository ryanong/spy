require 'test_helper'

module Spy
  class TestSubroutine < MiniTest::Unit::TestCase
    def spy_on(base_object, method_name)
      Subroutine.new(base_object, method_name).hook
    end

    def setup
      Agency.instance.dissolve!
      @pen = Pen.new
    end

    def test_spy_on_hook_and_saves_spy
      pen_write_spy = spy_on(@pen, :write).and_return("hello")
      assert_equal "hello", @pen.write(nil)
      assert_kind_of Subroutine, pen_write_spy
      assert_equal [pen_write_spy], Agency.instance.subroutines
      assert pen_write_spy.has_been_called?
    end

    def test_spy_can_hook_and_record_a_method_call
      pen_write_spy = spy_on(@pen, :write)
      refute pen_write_spy.has_been_called?
      @pen.write("hello")
      assert pen_write_spy.has_been_called?
      assert_empty @pen.written
    end

    def test_spy_can_hook_and_record_a_method_call_on_a_constant
      another_spy = spy_on(Pen, :another)
      refute another_spy.has_been_called?
      assert_nil Pen.another
      assert another_spy.has_been_called?
      another_spy.unhook
      assert_equal "another", Pen.another
    end

    def test_spy_can_unhook_a_method
      pen_write_spy = spy_on(@pen, :write)
      pen_write_spy.unhook
      @pen.write("hello")
      refute pen_write_spy.has_been_called?
    end

    def test_spy_cannot_hook_a_non_existent_method
      spy = Subroutine.new(@pen, :no_method)
      assert_raises NameError do
        spy.hook
      end
    end

    def test_spy_can_hook_a_non_existent_method_if_param_set
      spy = Subroutine.new(@pen, :no_method).and_return(:yep)
      spy.hook(force: true)
      assert_equal :yep, @pen.no_method
    end

    def test_spy_and_return_returns_the_set_value
      result = "hello world"

      spy_on(@pen, :write).and_return(result)

      assert_equal result, @pen.write(nil)
    end

    def test_spy_and_return_can_call_a_block
      result = "hello world"

      spy_on(@pen, :write).and_return {}.and_return do |string|
        string.reverse
      end

      assert_equal result.reverse, @pen.write(result)
      assert_empty @pen.written
    end

    def test_spy_and_return_can_call_a_block_raises_when_there_is_an_arity_mismatch
      write_spy = spy_on(@pen, :write)
      write_spy.and_return do |*args|
      end
      write_spy.and_return do |string, *args|
      end
      assert_raises ArgumentError do
        write_spy.and_return do |string, b|
        end
      end
    end

    def test_spy_and_return_can_call_a_block_that_recieves_a_block
      string = "hello world"

      spy_on(@pen, :write_block).and_return do |&block|
        block.call
      end

      result = @pen.write_block do
        string
      end
      assert_equal string, result
    end

    def test_spy_hook_records_number_of_calls
      pen_write_spy = spy_on(@pen, :write)
      assert_equal 0, pen_write_spy.calls.size
      5.times do |i|
        @pen.write("hello world")
        assert_equal i + 1, pen_write_spy.calls.size
      end
    end

    def test_has_been_called_with?
      pen_write_spy = spy_on(@pen, :write)
      refute pen_write_spy.has_been_called_with?("hello")
      @pen.write("hello")
      assert pen_write_spy.has_been_called_with?("hello")
      @pen.write("world")
      assert pen_write_spy.has_been_called_with?("hello")
      @pen.write("hello world")
      assert pen_write_spy.has_been_called_with?("hello")
    end

    def test_spy_hook_records_number_of_calls
      args = ["hello world"]
      block = Proc.new {}
      pen_write_spy = spy_on(@pen, :write)
      called_from = "#{__FILE__}:#{__LINE__ + 1}:in `#{__method__}'"
      @pen.write(*args, &block)
      call_log = pen_write_spy.calls.first
      assert_equal @pen, call_log.object
      assert_equal args, call_log.args
      assert_equal block, call_log.block
      assert_equal called_from, call_log.called_from
    end

    def test_that_method_spy_keeps_arity
      spy_on(@pen, :write)
      @pen.write("hello world")
      assert_raises ArgumentError do
        @pen.write("hello", "world")
      end

      spy_on(@pen, :write_hello)
      @pen.write_hello
      assert_raises ArgumentError do
        @pen.write_hello("hello")
      end

      spy_on(@pen, :write_array)
      @pen.write_hello
      assert_raises ArgumentError do
        @pen.write_hello("hello")
      end

      spy_on(@pen, :greet)
      @pen.greet("bob")
      assert_raises ArgumentError do
        @pen.greet
      end
      assert_raises ArgumentError do
        @pen.greet("hello", "bob", "error")
      end
    end

    def test_hook_mimics_public_visibility
      spy_on(@pen, :public_method)
      assert @pen.singleton_class.public_method_defined? :public_method
      refute @pen.singleton_class.protected_method_defined? :public_method
      refute @pen.singleton_class.private_method_defined? :public_method
    end

    def test_hook_mimics_protected_visibility
      spy_on(@pen, :protected_method)
      refute @pen.singleton_class.public_method_defined? :protected_method
      assert @pen.singleton_class.protected_method_defined? :protected_method
      refute @pen.singleton_class.private_method_defined? :protected_method
    end

    def test_hook_mimics_private_visibility
      spy_on(@pen, :private_method)
      refute @pen.singleton_class.public_method_defined? :private_method
      refute @pen.singleton_class.protected_method_defined? :private_method
      assert @pen.singleton_class.private_method_defined? :private_method
    end

    def test_spy_get_can_retrieve_a_spy
      pen_write_spy = spy_on(@pen, :write).and_return(:hello)
      assert_equal :hello, @pen.write(:world)
      assert_equal pen_write_spy, Subroutine.get(@pen, :write)
      assert Subroutine.get(@pen, :write).has_been_called?
    end
  end
end
