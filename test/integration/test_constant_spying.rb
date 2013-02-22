require 'test_helper'

class TestConstantSpying < MiniTest::Unit::TestCase

  class Foo
    HELLO = "hello world"

    def self.hello
      HELLO
    end

    module Bar
      def self.hello
        HELLO
      end
    end
  end

  class ChildFoo < Foo
    def self.hello
      HELLO
    end
  end

  def teardown
    Spy::Agency.instance.dissolve!
  end

  def test_spy_on_constant
    assert_equal "hello world", Foo.hello

    spy = Spy.on_const(Foo, :HELLO)
    assert_equal nil, Foo.hello
    spy.and_return("awesome")
    assert_equal "awesome", Foo.hello

    Spy.off_const(Foo, :HELLO)
    assert_equal "hello world", Foo.hello

    assert_equal "hello world", Foo::Bar.hello
    spy = Spy.on_const(Foo, :HELLO)
    assert_equal nil, Foo::Bar.hello
    spy.and_return("awesome")
    assert_equal "awesome", Foo::Bar.hello

    Spy.off_const(Foo, :HELLO)
    assert_equal "hello world", Foo::Bar.hello

    assert_equal "hello world", ChildFoo.hello
    spy = Spy.on_const(Foo, :HELLO)
    assert_equal nil, ChildFoo.hello
    spy.and_return("awesome")
    assert_equal "awesome", ChildFoo.hello

    Spy.off_const(Foo, :HELLO)
    assert_equal "hello world", ChildFoo.hello
  end
end
