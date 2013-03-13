require 'singleton'

module Spy
  # Manages all the spies
  class Agency
    include Singleton

    # @private
    def initialize
      clear!
    end

    # given a spy ID it will return the associated spy
    # @param id [Integer] spy object id
    # @return [Nil, Subroutine, Constant, Double]
    def find(id)
      @spies[id]
    end

    # Record that a spy was initialized and hooked
    # @param spy [Subroutine, Constant, Double]
    # @return [spy]
    def recruit(spy)
      raise AlreadyStubbedError if @spies[spy.object_id]
      check_spy!(spy)
      @spies[spy.object_id] = spy
    end

    # remove spy from the records
    # @param spy [Subroutine, Constant, Double]
    # @return [spy]
    def retire(spy)
      raise NoSpyError unless @spies[spy.object_id]
      @spies.delete(spy.object_id)
    end

    # checks to see if a spy is hooked
    # @param spy [Subroutine, Constant, Double]
    # @return [Boolean]
    def active?(spy)
      check_spy!(spy)
      @spies.has_key?(spy.object_id)
    end

    # unhooks all spies and clears records
    # @return [self]
    def dissolve!
      @spies.values.each do |spy|
        spy.unhook if spy.respond_to?(:unhook)
      end
      clear!
    end

    # clears records
    # @return [self]
    def clear!
      @spies = {}
      self
    end

    # returns all the spies that have been initialized since the creation of
    # this agency
    # @return [Array<Subroutine, Constant, Double>]
    def spies
      @spies.values
    end

    private

    def check_spy!(spy)
      raise ArgumentError, "#{spy}, was not a spy" unless spy.is_a?(Base)
    end
  end
end
