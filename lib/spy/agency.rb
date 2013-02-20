require 'singleton'

module Spy
  # Manages all the spies
  class Agency
    include Singleton

    # @!attribute [r] subroutines
    #   @return [Array<Subroutine>] all the subroutines that have been hooked
    #
    # @!attribute [r] constants
    #   @return [Array<Constant>] all the constants that have been hooked
    #
    # @!attribute [r] doubles
    #   @return [Array<Double>] all the doubles that have been created


    attr_reader :subroutines, :constants, :doubles

    # @private
    def initialize
      clear!
    end

    # Record that a spy was initialized and hooked
    # @param spy [Subroutine, Constant, Double]
    # @return [spy]
    def recruit(spy)
      case spy
      when Subroutine
        subroutines << spy
      when Constant
        constants << spy
      when Double
        doubles << spy
      else
        raise "Not a spy"
      end
      spy
    end

    # remove spy from the records
    # @param spy [Subroutine, Constant, Double]
    # @return [spy]
    def retire(spy)
      case spy
      when Subroutine
        subroutines.delete(spy)
      when Constant
        constants.delete(spy)
      when Double
        doubles.delete(spy)
      else
        raise "Not a spy"
      end
      spy
    end

    # checks to see if a spy is hooked
    # @param spy [Subroutine, Constant, Double]
    # @return [Boolean]
    def active?(spy)
      case spy
      when Subroutine
        subroutines.include?(spy)
      when Constant
        constants.include?(spy)
      when Double
        doubles.include?(spy)
      end
    end

    # unhooks all spies and clears records
    # @return [self]
    def dissolve!
      subroutines.each(&:unhook)
      constants.each(&:unhook)
      clear!
    end

    # clears records
    # @return [self]
    def clear!
      @subroutines = []
      @constants = []
      @doubles = []
      self
    end
  end
end
