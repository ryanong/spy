require 'spy'

module Spy
  if defined?(::MiniTest::Unit::TestCase)
    class MiniTestAdapter
      include API
      def after_teardown
        super
        Spy.teardown
      end
    end

    ::MiniTest::Unit::TestCase.send(:include, MiniTestAdapter)
  end

  if defined?(::Test::Unit::TestCase) && !(defined?(::MiniTest::Unit::TestCase) && (::Test::Unit::TestCase < ::MiniTest::Unit::TestCase)) && !(defined?(::MiniTest::Spec) && (::Test::Unit::TestCase < ::MiniTest::Spec))

    class TestUnitAdapter
      include API
      def self.included(mod)
        mod.teardown :spy_teardown, :after => :append
      end

      def spy_teardown
        Spy.teardown
      end
    end

    ::Test::Unit::TestCase.send(:include, TestUnitAdapter)
  end

  if defined?(::Rspec)
end
