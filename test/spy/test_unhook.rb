require 'test_helper'

module Spy
  class TestUnhook < Minitest::Test
    module ModuleFunctionStyle
      extend self

      def hello
        'hello world'
      end
    end

    module Injected
      def hello
        'hello world'
      end
    end

    class ModuleInjectedStyle
      include Injected
    end

    class ModuleExtendedStyle
      extend Injected
    end

    class SingletonMethodStyle
      def self.hello
        'hello world'
      end
    end

    class InstanceMethodStyle
      def hello
        'hello world'
      end
    end

    def test_ModuleFunctionStyle
      spy = Spy.on(ModuleFunctionStyle, :hello).and_return('yo')
      assert_equal ModuleFunctionStyle.hello, 'yo'
      spy.unhook
      assert_equal ModuleFunctionStyle.hello, 'hello world'
    end

    def test_ModuleInjectedStyle
      instance = ModuleInjectedStyle.new
      spy = Spy.on(instance, :hello).and_return('yo')
      assert_equal instance.hello, 'yo'
      spy.unhook
      assert_equal instance.hello, 'hello world'
    end

    def test_ModuleExtendedStyle
      spy = Spy.on(ModuleExtendedStyle, :hello).and_return('yo')
      assert_equal ModuleExtendedStyle.hello, 'yo'
      spy.unhook
      assert_equal ModuleExtendedStyle.hello, 'hello world'
    end

    def test_SingletonMethodStyle
      spy = Spy.on(SingletonMethodStyle, :hello).and_return('yo')
      assert_equal SingletonMethodStyle.hello, 'yo'
      spy.unhook
      assert_equal SingletonMethodStyle.hello, 'hello world'
    end

    def test_InstanceMethodStyle
      instance = InstanceMethodStyle.new
      spy = Spy.on(instance, :hello).and_return('yo')
      assert_equal instance.hello, 'yo'
      spy.unhook
      assert_equal instance.hello, 'hello world'
    end
  end
end
