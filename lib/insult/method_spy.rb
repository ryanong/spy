module Insult
  class MethodSpy
    attr_reader :base_object
    def initialize(object, method_name)
      @base_object, @method_name = object, method_name
      reset!
    end

    def was_called?
      @calls.size > 0
    end

    def called_with(args, &block)
      @calls << {args: args, block: block}
      nil
    end

    def reset!
      @calls = []
    end
  end
end
