module Spy
  class CallLog

    # @!attribute [r] object
    #   @return [Object] object that the method was called from
    #
    # @!attribute [r] called_from
    #   @return [String] where the method was called from
    #
    # @!attribute [r] args
    #   @return [Array] arguments were sent to the method
    #
    # @!attribute [r] block
    #   @return [Proc] the block that was sent to the method
    #
    # @!attribute [r] result
    #   @return The result of the method of being stubbed, or called through


    attr_reader :object, :called_from, :args, :block, :result

    def initialize(object, called_from, args, block, result)
      @object, @called_from, @args, @block, @result = object, called_from, args, block, result
    end
  end
end
