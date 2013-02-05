require 'test_helper'

class Spy
  class TestDouble < MiniTest::Unit::TestCase
    def test_double_creation
      double = Double.new("NewDouble", :meth_1, :meth_2)

      assert_nil double.meth_1
      assert_nil double.meth_2
    end

    def test_double_hash_input
      double = Double.new("NewDouble", meth_1: :meth_1, meth_2: :meth_2)

      assert_equal :meth_1, double.meth_1
      assert_equal :meth_2, double.meth_2
    end
  end
end
