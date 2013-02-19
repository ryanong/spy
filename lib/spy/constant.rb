module Spy
  class Constant
    attr_reader :base_module, :constant_name, :original_value, :new_value

    def initialize(base_module, constant_name)
      raise "#{base_module.inspect} is not a kind of Module" unless base_module.is_a? Module
      raise "#{constant_name.inspect} is not a kind of Symbol" unless constant_name.is_a? Symbol
      @base_module, @constant_name = base_module, constant_name.to_sym
      @original_value = nil
      @new_value = nil
      @was_defined = nil
    end

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

    def unhook
      if @was_defined
        and_return(@original_value)
      end
      @original_value = nil

      Agency.instance.retire(self)
      Nest.fetch(base_module).remove(self)
      self
    end

    def and_hide
      base_module.send(:remove_const, constant_name)
      self
    end

    def and_return(value)
      @new_value = value
      base_module.send(:remove_const, constant_name) if base_module.const_defined?(constant_name, false)
      base_module.const_set(constant_name, @new_value)
      self
    end

    def hooked?
      Nest.get(base_module).hooked?(constant_name)
    end

    class << self
      def on(base_module, constant_name)
        new(base_module, constant_name).hook
      end

      def off(base_module, constant_name)
        get(base_module, constant_name).unhook
      end

      def get(base_module, constant_name)
        Nest.get(base_module).hooked_constants[constant_name]
      end
    end
  end
end
