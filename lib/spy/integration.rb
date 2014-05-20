require 'spy'

module Spy
  if defined?(::MiniTest::Unit::TestCase) || defined?(::Minitest::Test)
    module MiniTestAdapter
      include API
      def after_teardown
        super
        Spy.teardown
      end
    end

    if defined?(::MiniTest::Unit::TestCase) && !::MiniTest::Unit::TestCase.include?(MiniTestAdapter)
      ::MiniTest::Unit::TestCase.send(:include, MiniTestAdapter)
    end

    if defined?(::Minitest::Test) && !::Minitest::Test.include?(MiniTestAdapter)
     ::Minitest::Test.send(:include, MiniTestAdapter)
    end
  end

  if defined?(::Test::Unit::TestCase) && !(defined?(::MiniTest::Unit::TestCase) && (::Test::Unit::TestCase < ::MiniTest::Unit::TestCase)) && !(defined?(::MiniTest::Spec) && (::Test::Unit::TestCase < ::MiniTest::Spec))

    module TestUnitAdapter
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

  class RspecAdapter
    include API
    def setup_mocks_for_rspec
    end
    def verify_mocks_for_rspec
    end
    def teardown_mocks_for_rspec
      Spy.teardown
    end
  end
end
