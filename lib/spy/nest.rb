module Spy
  class Nest
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

    def inject
      raise "Nest already injected" if injected?

      __constant_spy = self
      base_module.define_singleton_method(:const_missing,__spy_constant_name) do |__spy_constant_name|
        if __spy_constant_name === SECRET_SPY_KEY
          __constant_spy
        else
          __constant_spy.invoke(__spy_constant_name).call
        end
      end
      base_module.singleton_class.send(:private, :const_missing)
      self
    end

    def injected?
      self == self.class.get(base_module)
    end

    def injected?(constant_name)
      self.class.get(constant_name) == self
    end

    def hooked?(constant_name)
      !!@hooked_constants[constant_name]
    end

    def invoke(constant_name)
      @hooked_constants[constant_name].try(:invoke) || Constant::SUPER_PROC
    end

    class << self
      def get(base_module)
        if base_module.singleton_class.private_instance_methods.include(:const_missing) && base_module.method(:const_missing).parameters([[:req, :__spy_constant_name]])
          base_module.send(:const_missing, SECRET_SPY_KEY)
        end
      end
    end
  end
end
