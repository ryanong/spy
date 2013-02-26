module Spy
  # This class manages all the Constant Mutations for a given Module
  class Nest

    # @!attribute [r] base_module
    #   @return [Module] The module that the Nest is managing
    #
    # @!attribute [r] hooked_constants
    #   @return [Hash<Symbol, Constant>] The module that the Nest is managing


    attr_reader :base_module, :hooked_constants

    def initialize(base_module)
      raise "#{base_module} is not a kind of Module" unless base_module.is_a?(Module)
      @base_module = base_module
      @hooked_constants = {}
    end

    # records that the spy is hooked
    # @param spy [Constant]
    # @return [self]
    def add(spy)
      if @hooked_constants[spy.constant_name]
        raise "#{spy.constant_name} has already been stubbed"
      else
        @hooked_constants[spy.constant_name] = spy
      end
      self
    end

    # removes the spy from the records
    # @param spy [Constant]
    # @return [self]
    def remove(spy)
      if @hooked_constants[spy.constant_name] == spy
        @hooked_constants.delete(spy.constant_name)
      else
        raise "#{spy.constant_name} was never added"
      end
      self
    end

    # checks to see if a given constant is hooked
    # @param constant_name [Symbol]
    # @return [Boolean]
    def hooked?(constant_name)
      !!@hooked_constants[constant_name]
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
