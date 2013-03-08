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
      raise ArgumentError, "#{base_module.inspect} is not a kind of Module" unless base_module.is_a? Module
      raise ArgumentError, "#{constant_name.inspect} is not a kind of Symbol" unless constant_name.is_a? Symbol
      @base_module, @constant_name = base_module, constant_name.to_sym
      @original_value = @new_value = @previously_defined = nil
    end

    # full name of spied constant
    def name
      "#{base_module.name}::#{constant_name}"
    end

    # stashes the original constant then overwrites it with nil
    # @param opts [Hash{force => false}] set :force => true if you want it to ignore if the constant exists
    # @return [self]
    def hook(opts = {})
      opts[:force] ||= false
      Nest.fetch(base_module).add(self)
      Agency.instance.recruit(self)

      @previously_defined = currently_defined?
      if previously_defined? || !opts[:force]
        @original_value = base_module.const_get(constant_name, false)
      end
      and_return(@new_value)
      self
    end

    # restores the original value of the constant or unsets it if it was unset
    # @return [self]
    def unhook
      Nest.get(base_module).remove(self)
      Agency.instance.retire(self)

      and_return(@original_value) if previously_defined?

      @original_value = @previously_defined = nil
      self
    end

    # unsets the constant
    # @return [self]
    def and_hide
      base_module.send(:remove_const, constant_name) if currently_defined?
      self
    end

    # sets the constant to the requested value
    # @param value [Object]
    # @return [self]
    def and_return(value)
      @new_value = value
      and_hide
      base_module.const_set(constant_name, @new_value)
      self
    end

    # checks to see if this spy is hooked?
    # @return [Boolean]
    def hooked?
      self.class.get(base_module, constant_name) == self
    end

    # checks to see if the constant is hidden?
    # @return [Boolean]
    def hidden?
      hooked? && currently_defined?
    end

    # checks to see if the constant is currently defined?
    # @return [Boolean]
    def currently_defined?
      base_module.const_defined?(constant_name, false)
    end

    # checks to see if the constant is previously defined?
    # @return [Boolean]
    def previously_defined?
      @previously_defined
    end

    class << self
      # finds existing spy or creates a new constant spy and hooks the constant
      # @return [Constant]
      def on(base_module, constant_name)
        get(base_module, constant_name) ||
          new(base_module, constant_name).hook
      end

      # retrieves the spy for given constant and module and unhooks the constant
      # from the module
      # @return [Constant]
      def off(base_module, constant_name)
        spy = get(base_module, constant_name)
        raise NoSpyError, "#{constant_name} was not spied on #{base_module}" unless spy
        spy.unhook
      end

      # retrieves the spy for given constnat and module or returns nil
      # @return [Nil, Constant]
      def get(base_module, constant_name)
        nest = Nest.get(base_module)
        if nest
          nest.get(constant_name)
        end
      end
    end
  end
end
