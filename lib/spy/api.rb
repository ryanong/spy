module Spy
  module API
    DidNotReceiveError = Class.new(Spy::Error)

    def assert_received(base_object, method_name)
      assert Subroutine.get(base_object, method_name).has_been_called?,
        "#{method_name} was not called on #{base_object.inspect}"
    end

    def assert_received_with(base_object, method_name, *args, &block)
      assert Subroutine.get(base_object, method_name).has_been_called_with?(*args, &block),
        "#{method_name} was not called on #{base_object.inspect} with #{args.inspect}"
    end

    def have_received(method_name)
      HaveReceived.new(method_name)
    end

    class HaveReceived
      attr_reader :method_name, :actual

      def initialize(method_name)
        @method_name = method_name
        @with = nil
      end

      def matches?(actual)
        @actual = actual
        case @with
        when Proc
          spy.has_been_called_with?(&@with)
        when Array
          spy.has_been_called_with?(*@with)
        else
          spy.has_been_called?
        end
      end

      def with(*args)
        @with = block_given? ? Proc.new : args
        self
      end

      def failure_message_for_should
        "expected #{actual.inspect} to have received #{method_name.inspect}#{args_message}"
      end

      def failure_message_for_should_not
        "expected #{actual.inspect} to not have received #{method_name.inspect}#{args_message}, but did"
      end

      def description
        "to have received #{method_name.inspect}#{args_message}"
      end

      private

      def args_message
        case @with
        when Array
          " with #{@with.inspect}"
        when Proc
          " with given block"
        end
      end

      def spy
        @spy ||= Subroutine.get(@actual, @method_name)
      end
    end
  end
end
