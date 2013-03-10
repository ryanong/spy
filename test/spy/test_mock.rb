module Spy
  class TestMock < MiniTest::Unit::TestCase

    def setup
      @pen = Spy::Mock.new(Pen)
    end

    def test_mock_class_methods
      assert @pen.kind_of?(Pen)
      assert @pen.is_a?(Pen)
      assert @pen.instance_of?(Pen)
      assert_equal Pen, @pen.class
    end
  end
end
