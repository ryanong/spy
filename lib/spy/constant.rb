module Spy
  class Constant

    # @!attribute [r] base_module
    #   @return [Module] the module that is being watched
    #
    # @!attribute [r] constant_name
    #   @return [Symbol] the name of the constant that is/will be stubbed
    #
    # @!attribute [r] original_value
    #   @return [Object] the original value that was set when it was hooked


    attr_reader :base_module, :constant_name, :original_value

    # @param base_module [Module] the module this spy should be on
    # @param constant_name [Symbol] the constant this spy is watching
    def initialize(base_module, constant_name)
      raise "#{base_module.inspect} is not a kind of Module" unless base_module.is_a? Module
      raise "#{constant_name.inspect} is not a kind of Symbol" unless constant_name.is_a? Symbol
      @base_module, @constant_name = base_module, constant_name.to_sym
      @original_value = nil
      @new_value = nil
      @was_defined = nil
    end

    # stashes the original constant then overwrites it with nil
    # @param opts [Hash{force => false}] set :force => true if you want it to ignore if the constant exists
    # @return [self]
    def hook(opts = {})
      opts[:force] ||= false
      @was_defined = base_module.const_defined?(constant_name, false)
      if @was_defined || !opts[:force]
        @original_value = base_module.const_get(constant_name, false)
      end
      and_return(@new_value)
      Nest.fetch(base_module).add(self)
      Agency.instance.recruit(self)
      self
    end

    # restores the original value of the constant or unsets it if it was unset
    # @return [self]
    def unhook
      if @was_defined
        and_return(@original_value)
      end
      @original_value = nil

      Agency.instance.retire(self)
      Nest.fetch(base_module).remove(self)
      self
    end

    # unsets the constant
    # @return [self]
    def and_hide
      base_module.send(:remove_const, constant_name)
      self
    end

    # sets the constant to the requested value
    # @param value [Object]
    # @return [self]
    def and_return(value)
      @new_value = value
      base_module.send(:remove_const, constant_name) if base_module.const_defined?(constant_name, false)
      base_module.const_set(constant_name, @new_value)
      self
    end

    # checks to see if this spy is hooked?
    # @return [Boolean]
    def hooked?
      self.class.get(base_module) == self
    end

    class << self
      # creates a new constant spy and hooks the constant
      # @return [Constant]
      def on(base_module, constant_name)
        new(base_module, constant_name).hook
      end

      # retrieves the spy for given constant and module and unhooks the constant
      # from the module
      # @return [Constant]
      def off(base_module, constant_name)
        get(base_module, constant_name).unhook
      end

      # retrieves the spy for given constnat and module or returns nil
      # @return [Nil, Constant]
      def get(base_module, constant_name)
        Nest.get(base_module).hooked_constants[constant_name]
      end
    end
  end
end
