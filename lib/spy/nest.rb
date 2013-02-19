module Spy
  class Nest
    attr_reader :base_module, :hooked_constants

    def initialize(base_module)
      raise "#{base_module} is not a kind of Module" unless base_module.is_a?(Module)
      @base_module = base_module
      @hooked_constants = {}
    end

    def add(spy)
      if @hooked_constants[spy.constant_name]
        raise "#{spy.constant_name} has already been stubbed"
      else
        @hooked_constants[spy.constant_name] = spy
      end
      self
    end

    def remove(spy)
      if @hooked_constants[spy.constant_name] == spy
        @hooked_constants.delete(spy.constant_name)
      end
      self
    end

    def hooked?(constant_name)
      !!@hooked_constants[constant_name]
    end

    class << self
      def get(base_module)
        all[base_module.name]
      end

      def fetch(base_module)
        all[base_module.name] ||= self.new(base_module)
      end

      def all
        @all ||= {}
      end
    end
  end
end
