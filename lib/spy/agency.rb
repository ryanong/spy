require 'singleton'

module Spy
  class Agency
    include Singleton

    attr_reader :subroutines, :constants, :doubles

    def initialize
      clear!
    end

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

    def dissolve!
      subroutines.each(&:unhook)
      constants.each(&:unhook)
      clear!
    end

    def clear!
      @subroutines = []
      @constants = []
      @doubles = []
      self
    end
  end
end
