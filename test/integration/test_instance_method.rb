require 'test_helper'

class TestAnyInstanceOf < MiniTest::Unit::TestCase
  class Foo
    def bar
      "foobar"
    end
  end

  def teardown
    Spy::Agency.instance.dissolve!
  end

  def test_it_overides_all_methods
    assert_equal Foo.new.bar, "foobar"
    spy = Spy.on_instance_method(Foo, bar: "timshel")
    assert_equal spy, Spy::Subroutine.get(Foo, :bar, false)
    assert_equal Foo.new.bar, "timshel"
    assert_equal Foo.new.bar, "timshel"
    assert_equal 2, spy.calls.size

    spy = Spy.off_instance_method(Foo, :bar)
    assert_equal Foo.new.bar, "foobar"
  end
end
