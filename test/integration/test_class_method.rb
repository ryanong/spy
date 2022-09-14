require 'test_helper'

class TestClassMethod < Minitest::Test
  def teardown
    Spy::Agency.instance.dissolve!
  end

  def test_and_return
    klass = Class.new do
      def self.class_method(*args, &block)
      end
    end
    received_args = nil
    received_block = nil
    Spy.on(klass, :class_method).and_return do |*args, &block|
      received_args = args
      received_block = block
    end
    block = -> {}
    klass.class_method(:a, :b, &block)
    assert_equal [:a, :b], received_args
    assert_equal block, received_block
  end
end
