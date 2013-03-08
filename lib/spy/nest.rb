module Spy
  # This class manages all the Constant Mutations for a given Module
  class Nest

    # @!attribute [r] base_module
    #   @return [Module] The module that the Nest is managing
    #
    # @!attribute [r] constant_spies
    #   @return [Hash<Symbol, Constant>] The module that the Nest is managing


    attr_reader :base_module

    def initialize(base_module)
      raise ArgumentError, "#{base_module} is not a kind of Module" unless base_module.is_a?(Module)
      @base_module = base_module
      @constant_spies = {}
    end

    # records that the spy is hooked
    # @param spy [Constant]
    # @return [self]
    def add(spy)
      if @constant_spies[spy.constant_name]
        raise AlreadyStubbedError, "#{spy.constant_name} has already been stubbed"
      else
        @constant_spies[spy.constant_name] = spy
      end
      self
    end

    # removes the spy from the records
    # @param spy [Constant]
    # @return [self]
    def remove(spy)
      if @constant_spies[spy.constant_name] == spy
        @constant_spies.delete(spy.constant_name)
      else
        raise NoSpyError, "#{spy.constant_name} was not stubbed on #{base_module.name}"
      end
      self
    end

    # returns a spy if the constant was added
    # @param constant_name [Symbol]
    # @return [Constant, nil]
    def get(constant_name)
      @constant_spies[constant_name]
    end

    # checks to see if a given constant is hooked
    # @param constant_name [Symbol]
    # @return [Boolean]
    def hooked?(constant_name)
      !!get(constant_name)
    end

    # list all the constants that are being stubbed
    # @return [Array]
    def hooked_constants
      @constant_spies.keys
    end

    class << self
      # retrieves the nest for a given module
      # @param base_module [Module]
      # @return [Nil, Nest]
      def get(base_module)
        all[base_module.name]
      end

      # retrieves the nest for a given module or creates it
      # @param base_module [Module]
      # @return [Nest]
      def fetch(base_module)
        all[base_module.name] ||= self.new(base_module)
      end

      # returns all the hooked constants
      # @return [Hash<String, Constant>]
      def all
        @all ||= {}
      end
    end
  end
end
