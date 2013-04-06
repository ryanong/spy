require 'test_helper'

class TestApi < MiniTest::Unit::TestCase
  include Spy::API

  def setup
    @pen = Pen.new
    Spy.on(@pen, :write)
  end

  def test_assert_received
    @pen.write(:hello)
    assert_received(@pen, :write)
  end

  def test_assert_received_with
    @pen.write(:world)
    assert_received_with(@pen, :write, :world)
    assert_received_with(@pen, :write) do |call|
      call.args == [:world]
    end
  end

  def test_have_received
    @pen.write(:foo)
    matcher = have_received(:write)
    assert matcher.matches?(@pen)
  end

  def test_have_received_with
    @pen.write(:bar)
    matcher = have_received(:write).with(:bar)
    assert matcher.matches?(@pen)

    matcher = have_received(:write).with do |call|
      call.args == [:bar]
    end
    assert matcher.matches?(@pen)
  end
end
