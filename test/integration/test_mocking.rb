require 'test_helper'

class TestMocking < MiniTest::Unit::TestCase
  def teardown
    Spy::Agency.instance.dissolve!
  end

  def test_spy_on_mock_does_not_raise
    mock = Spy.mock(Pen)
    spy = Spy.on(mock, :write).and_return(:awesome)
    assert_equal :awesome, mock.write("hello")
    assert spy.has_been_called?
  end

  def test_spy_mock_shortcuts
    mock = Spy.mock(Pen, :another, write_hello: :goodbye)
    assert_nil mock.another
    assert_equal :goodbye, mock.write_hello
  end

  def test_spy_mock_all
    mock = Spy.mock_all(Pen)
    assert_nil mock.another
  end
end
