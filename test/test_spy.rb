require 'test_helper'

class TestSpy < MiniTest::Unit::TestCase
  def setup
    Spy::Agency.instance.dissolve!
    @pen = Pen.new
  end

  def test_spy_on_hooks_and_saves_spy_with_array
    pen_write_spy, pen_write_hello_spy = Spy::Subroutine.on(@pen, :write, :write_hello)
    assert_nil @pen.write(nil)
    assert_nil @pen.write_hello

    assert_kind_of Spy::Subroutine, pen_write_spy
    assert_kind_of Spy::Subroutine, pen_write_hello_spy
    assert_equal [pen_write_spy, pen_write_hello_spy], Spy::Agency.instance.subroutines
    assert pen_write_spy.has_been_called?
    assert pen_write_hello_spy.has_been_called?
  end

  def test_spy_on_hooks_and_saves_spy_with_array
    pen_write_spy, pen_write_hello_spy = Spy.on(@pen, write: "hello", write_hello: "world")
    assert_equal "hello", @pen.write(nil)
    assert_equal "world", @pen.write_hello

    assert_kind_of Spy::Subroutine, pen_write_spy
    assert_kind_of Spy::Subroutine, pen_write_hello_spy
    assert_equal [pen_write_spy, pen_write_hello_spy], Spy::Agency.instance.subroutines
    assert pen_write_spy.has_been_called?
    assert pen_write_hello_spy.has_been_called?
  end

  def test_spy_off_unhooks_a_method
    pen_write_spy = Spy.on(@pen, :write)
    Spy.off(@pen,:write)
    assert_equal "hello world", @pen.write("hello world")
    refute pen_write_spy.has_been_called?
  end

end
