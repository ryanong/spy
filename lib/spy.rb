require "spy/core_ext/marshal"
require "spy/agency"
require "spy/call_log"
require "spy/constant"
require "spy/double"
require "spy/exceptions"
require "spy/nest"
require "spy/subroutine"
require "spy/version"

module Spy

  class << self
    # create a spy on given object
    # @param base_object
    # @param method_names *[Hash,Symbol] will spy on these methods and also set default return values
    # @return [Subroutine, Array<Subroutine>]
    def on(base_object, *method_names)
      spies = method_names.map do |method_name|
        create_and_hook_spy(base_object, method_name)
      end.flatten

      spies.size > 1 ? spies : spies.first
    end

    # removes the spy from the from the given object
    # @param base_object
    # @param method_names *[Symbol]
    # @return [Subroutine, Array<Subroutine>]
    def off(base_object, *method_names)
      removed_spies = method_names.map do |method_name|
        spy = Subroutine.get(base_object, method_name)
        if spy
          spy.unhook
        else
          raise NoSpyError, "#{method_name} was not hooked on #{base_object.inspect}."
        end
      end

      removed_spies.size > 1 ? removed_spies : removed_spies.first
    end

    #
    def on_instance_method(base_class, *method_names)
      spies = method_names.map do |method_name|
        create_and_hook_spy(base_class, method_name, false)
      end.flatten

      spies.size > 1 ? spies : spies.first
    end

    def off_instance_method(base_object, *method_names)
      removed_spies = method_names.map do |method_name|
        spy = Subroutine.get(base_object, method_name, false)
        if spy
          spy.unhook
        else
          raise NoSpyError, "#{method_name} was not hooked on #{base_object.inspect}."
        end
      end

      removed_spies.size > 1 ? removed_spies : removed_spies.first
    end

    # create a stub for constants on given module
    # @param base_module [Module]
    # @param constant_names *[Symbol, Hash]
    # @return [Constant, Array<Constant>]
    def on_const(base_module, *constant_names)
      if base_module.is_a?(Hash) || base_module.is_a?(Symbol)
        constant_names.unshift(base_module)
        base_module = Object
      end
      spies = constant_names.map do |constant_name|
        case constant_name
        when Symbol
          Constant.on(base_module, constant_name)
        when Hash
          constant_name.map do |name, result|
            Constant.on(base_module, name).and_return(result)
          end
        else
          raise ArgumentError, "#{constant_name.class} is an invalid input, #on only accepts Symbol, and Hash"
        end
      end.flatten

      spies.size > 1 ? spies : spies.first
    end

    # removes stubs from given module
    # @param base_module [Module]
    # @param constant_names *[Symbol]
    # @return [Constant, Array<Constant>]
    def off_const(base_module, *constant_names)
      if base_module.is_a?(Symbol)
        constant_names.unshift(base_module)
        base_module = Object
      end

      spies = constant_names.map do |constant_name|
        unless constant_name.is_a?(Symbol)
          raise ArgumentError, "#{constant_name.class} is an invalid input, #on only accepts Symbol, and Hash"
        end
        Constant.off(base_module, constant_name)
      end

      spies.size > 1 ? spies : spies.first
    end

    # unhook all methods
    def teardown
      Agency.instance.dissolve!
    end

    # returns a double
    # (see Double#initizalize)
    def double(*args)
      Double.new(*args)
    end

    # retrieve the spy from an object
    # @param base_object
    # @param method_names *[Symbol]
    # @return [Subroutine, Array<Subroutine>]
    def get(base_object, *method_names)
      spies = method_names.map do |method_name|
        Subroutine.get(base_object, method_name)
      end

      spies.size > 1 ? spies : spies.first
    end

    # retrieve the constant spies from an object
    # @param base_module
    # @param constant_names *[Symbol]
    # @return [Constant, Array<Constant>]
    def get_const(base_module, *constant_names)
      if base_module.is_a?(Symbol)
        constant_names.unshift(base_module)
        base_module = Object
      end

      spies = constant_names.map do |constant_name|
        Constant.get(base_module, constant_name)
      end

      spies.size > 1 ? spies : spies.first
    end

    private

    def create_and_hook_spy(base_object, method_name, singleton_method = true, hook_opts = {})
      case method_name
      when String, Symbol
        Subroutine.new(base_object, method_name, singleton_method).hook(hook_opts)
      when Hash
        method_name.map do |name, result|
          create_and_hook_spy(base_object, name, singleton_method, hook_opts).and_return(result)
        end
      else
        raise ArgumentError, "#{method_name.class} is an invalid input, #on only accepts String, Symbol, and Hash"
      end
    end
  end
end
