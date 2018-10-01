require 'test_helper'

class TestAnyInstanceOf < Minitest::Test
  class Foo
    def bar
      "foobar"
    end
  end

  class Bar < Foo
    def bar
      super
    end
  end

  def teardown
    Spy::Agency.instance.dissolve!
  end

  def test_call_through_with_instance_method
    Spy.on_instance_method(Foo, :bar).and_call_through
    assert_equal "foobar", Foo.new.bar
    Spy.off_instance_method(Foo, :bar)
  end

  def test_it_overides_all_methods
    assert_equal Foo.new.bar, "foobar"
    spy = Spy.on_instance_method(Foo, bar: "timshel")
    assert_equal spy, Spy::Subroutine.get(Foo, :bar, false)
    assert_equal "timshel", Foo.new.bar
    assert_equal "timshel", Foo.new.bar
    assert_equal "timshel", Bar.new.bar
    assert_equal 3, spy.calls.size

    spy = Spy.off_instance_method(Foo, :bar)
    assert_equal Foo.new.bar, "foobar"
  end
end
