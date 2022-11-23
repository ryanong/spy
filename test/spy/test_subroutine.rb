require 'test_helper'

module Spy
  class TestSubroutine < Minitest::Test
    def spy_on(base_object, method_name)
      Subroutine.new(base_object, method_name).hook
    end

    def spy_on_instance_method(base_object, method_name)
      Subroutine.new(base_object, method_name, false).hook
    end

    def setup
      @pen = Pen.new
    end

    def teardown
      Spy::Agency.instance.dissolve!
    end

    def test_spy_on_hook_and_saves_spy
      pen_write_spy = spy_on(@pen, :write).and_return("hello")
      assert_equal "hello", @pen.write(nil)
      assert_kind_of Subroutine, pen_write_spy
      assert_equal [pen_write_spy], Agency.instance.spies
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

    def test_spy_can_hook_and_record_a_meta_method_call_on_a_constant
      assert_equal "meta_class_method", Pen.meta_class_method
      meta_spy = spy_on(Pen, :meta_class_method)
      refute meta_spy.has_been_called?
      assert_nil Pen.meta_class_method
      assert meta_spy.has_been_called?
      meta_spy.unhook
      assert_equal "meta_class_method", Pen.meta_class_method
    end

    def test_spy_can_hook_record_and_unhook_a_meta_method
      assert_equal "meta_method", @pen.meta_method
      meta_spy = spy_on(@pen, :meta_method)
      refute meta_spy.has_been_called?
      assert_nil @pen.meta_method
      assert meta_spy.has_been_called?
      meta_spy.unhook
      assert_equal "meta_method", @pen.meta_method
    end

    def test_spy_can_unhook_a_method
      pen_write_spy = spy_on(@pen, :write)
      pen_write_spy.unhook
      assert_equal "hello", @pen.write("hello")
      refute pen_write_spy.has_been_called?
    end

    def test_spy_cannot_hook_a_non_existent_method
      spy = Subroutine.new(@pen, :no_method)
      assert_raises NameError do
        spy.hook
      end
    end

    def test_spy_can_hook_a_non_existent_method_if_param_set
      Subroutine.new(@pen, :no_method).hook(force:true).and_return(:yep)
      assert_equal :yep, @pen.no_method
    end

    def test_spy_and_return_returns_the_set_value
      result = "hello world"

      spy_on(@pen, :write).and_return(result)

      assert_equal result, @pen.write(nil)
    end

    def test_spy_and_raise_raises_the_set_exception
      pen_write_spy = spy_on(@pen, :write).and_raise(ArgumentError, "problems!")
      assert_kind_of Subroutine, pen_write_spy
      assert_equal [pen_write_spy], Agency.instance.spies

      e = assert_raises ArgumentError do
        @pen.write(nil)
      end
      assert_equal "problems!", e.message
      assert pen_write_spy.has_been_called?
    end

    def test_spy_and_return_can_call_a_block
      result = "hello world"

      spy_on(@pen, :write).and_return {}.and_return do |string|
        string.reverse
      end

      assert_equal result.reverse, @pen.write(result)
      assert_empty @pen.written
    end

    def test_spy_and_return_can_call_a_block_with_hash
      result = "hello world"

      spy_on(@pen, :write_hash).and_return { |**opts| opts[:test] }

      assert_equal result, @pen.write_hash(test: result)
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

      write_spy.and_return(force: true) do |string, b|
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

    def test_spy_and_call_through_with_hash_and_keyword_args
      spy_on(@pen, 'hash_and_keyword_arg').and_call_through
      hsh = { hello: 'world' }

      assert_equal [hsh, nil], @pen.hash_and_keyword_arg(hsh)
      assert_equal [hsh, 'foo'], @pen.hash_and_keyword_arg(hsh, keyword: 'foo')
    end

    def test_spy_and_call_through_returns_original_method_result
      string = "hello world"

      write_spy = spy_on(@pen, :write).and_call_through
      another_spy = spy_on(@pen, :another).and_call_through

      result = @pen.write(string)

      assert_equal string, result
      assert write_spy.has_been_called?
      assert_equal 'another', @pen.another
      assert another_spy.has_been_called?
    end

    def test_spy_and_call_through_with_hash_original_method
      string = 'test:hello world'

      write_spy = spy_on(@pen, :write_hash).and_call_through

      @pen.write_hash(test: 'hello world')
      assert_equal string, @pen.written.last
      assert write_spy.has_been_called?
    end

    def test_spy_on_instance_and_call_through_returns_original_method_result
      string = "hello world"

      inst_write_spy = spy_on_instance_method(Pen, :write).and_call_through
      inst_another_spy = spy_on_instance_method(Pen, :another).and_call_through

      result = @pen.write(string)

      assert_equal string, result
      assert inst_write_spy.has_been_called?
      assert_equal 'another', @pen.another
      assert inst_another_spy.has_been_called?
    end

    def test_spy_on_instance_and_call_through_with_hash
      string = 'test:hello world'

      inst_write_spy = spy_on_instance_method(Pen, :write_hash).and_call_through

      @pen.write_hash(test: 'hello world')

      assert_equal string, @pen.written.last
      assert inst_write_spy.has_been_called?
    end

    def test_spy_on_instance_and_call_through_to_aryable
      to_aryable = Class.new do
        def hello
          'hello'
        end

        def to_ary
          [1]
        end
      end

      inst_hello_spy = spy_on_instance_method(to_aryable, :hello).and_call_through
      inst = to_aryable.new

      assert_equal 'hello', inst.hello
      assert inst_hello_spy.has_been_called?
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

    def test_has_been_called_with_kwargs
      pen_write_spy = spy_on(@pen, :opt_kwargs)
      refute pen_write_spy.has_been_called_with?("hello")

      @pen.opt_kwargs("hello")
      assert pen_write_spy.has_been_called_with?("hello")

      @pen.opt_kwargs("world", opt: "hello")
      assert pen_write_spy.has_been_called_with?("world", opt: "hello")

      @pen.opt_kwargs("hello world", opt: "world", opt2: "hello")
      assert pen_write_spy.has_been_called_with?("hello world", opt: "world", opt2: "hello")
    end

    def test_spy_hook_records_number_of_calls2
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

    def test_that_method_spy_keeps_arity_with_optional_keyword_args
      spy_on(@pen, :opt_kwargs)
      @pen.opt_kwargs(:pos1)
      @pen.opt_kwargs(:pos1, opt: 1, opt2: 2)
      assert_raises ArgumentError do
        @pen.opt_kwargs
      end
      assert_raises ArgumentError do
        @pen.opt_kwargs(:pos1, :pos2, opt: 1)
      end
    end

    def test_that_method_spy_keeps_arity_with_keyword_splat
      spy_on(@pen, :keyrest)
      @pen.keyrest
      @pen.keyrest(a: 1, b: 2)
      assert_raises ArgumentError do
        @pen.keyrest(:pos1, :pos2)
      end
    end

    def test_that_method_spy_keeps_arity_with_required_keyword_args
      spy_on(@pen, :req_kwargs)
      @pen.req_kwargs(req1: 1, req2: 2)
      assert_raises ArgumentError do
        @pen.req_kwargs
      end
      assert_raises ArgumentError do
        @pen.req_kwargs(:pos1, :pos2)
      end
    end

    def test_hook_mimics_public_visibility
      spy_on(@pen, :public_method)
      assert @pen.singleton_class.public_method_defined? :public_method
    end

    def test_hook_mimics_protected_visibility
      spy_on(@pen, :protected_method)
      assert @pen.singleton_class.protected_method_defined? :protected_method
    end

    def test_hook_mimics_private_visibility
      spy_on(@pen, :private_method)
      assert @pen.singleton_class.private_method_defined? :private_method
    end

    def test_hook_mimics_class_public_visibility
      spy_on(Pen, :public_method)
      assert Pen.public_method_defined? :public_method
      Spy.off(Pen, :public_method)
      assert Pen.public_method_defined? :public_method
    end

    def test_hook_mimics_class_protected_visibility
      spy_on(Pen, :protected_method)
      assert Pen.protected_method_defined? :protected_method
      Spy.off(Pen, :protected_method)
      assert Pen.protected_method_defined? :protected_method
    end

    def test_hook_mimics_class_private_visibility
      spy_on(Pen, :private_method)
      assert Pen.private_method_defined? :private_method
      Spy.off(Pen, :private_method)
      assert Pen.private_method_defined? :private_method
    end

    def test_spy_get_can_retrieve_a_spy
      pen_write_spy = spy_on(@pen, :write).and_return(:hello)
      assert_equal :hello, @pen.write(:world)
      assert Subroutine.get(@pen, :write).has_been_called?
      assert_same pen_write_spy, Subroutine.get(@pen, :write)
    end

    def test_spy_hook_raises_an_error_on_an_already_hooked_method
      spy_on(@pen, :write)
      assert_raises AlreadyHookedError do
        spy_on(@pen, :write)
      end
    end
  end
end
