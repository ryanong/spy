require "spy/core_ext/marshal"
require "spy/agency"
require "spy/constant"
require "spy/double"
require "spy/dsl"
require "spy/nest"
require "spy/subroutine"
require "spy/version"

module Spy
  SECRET_SPY_KEY = Object.new
  class << self
    # create a spy on given object
    # @params base_object
    # @params *method_names [Symbol] will spy on these methods
    # @params *method_names [Hash] will spy on these methods and also set default return values
    # @return [Spy, Array<Spy>]
    def on(base_object, *method_names)
      spies = method_names.map do |method_name|
        create_and_hook_spy(base_object, method_name)
      end.flatten

      spies.size > 1 ? spies : spies.first
    end

    # removes the spy from the from the given object
    # @params base_object
    # @params *method_names
    # @return [Spy, Array<Spy>]
    def off(base_object, *method_names)
      removed_spies = method_names.map do |method_name|
        spy = Subroutine.get(base_object, method_name)
        if spy
          spy.unhook
        else
          raise "Spy was not found"
        end
      end

      removed_spies.size > 1 ? removed_spies : removed_spies.first
    end

    def on_const(base_module, *constant_names)
      if base_module.is_a? Symbol
        constant_names.unshift(base_module)
        base_module = Object
      end
      spies = constant_names.map do |constant_name|
        case constant_name
        when String, Symbol
          Constant.on(base_module, constant_name)
        when Hash
          constant_name.map do |name, result|
            on_const(base_module, name).and_return(result)
          end
        else
          raise ArgumentError.new "#{constant_name.class} is an invalid input, #on only accepts String, Symbol, and Hash"
        end
      end.flatten

      spies.size > 1 ? spies : spies.first
    end

    def off_const(base_module, *constant_names)
      spies = constant_names.map do |constant_name|
        case constant_name
        when String, Symbol
          Constant.off(base_module, constant_name)
        when Hash
          constant_name.map do |name, result|
            off_const(base_module, name).and_return(result)
          end
        else
          raise ArgumentError.new "#{constant_name.class} is an invalid input, #on only accepts String, Symbol, and Hash"
        end
      end.flatten

      spies.size > 1 ? spies : spies.first
    end

    # unhook all methods
    def teardown
      Agency.instance.dissolve!
    end

    # (see Double#new)
    def double(*args)
      Double.new(*args)
    end

    # retrieve the spy from an object
    # @params base_object
    # @method_names *[Symbol, Hash]
    def get(base_object, *method_names)
      spies = method_names.map do |method_name|
        Subroutine.get(base_object, method_name)
      end

      spies.size > 1 ? spies : spies.first
    end

    def get_const(base_module, *constant_names)
      spies = constant_names.map do |method_name|
        Constant.get(base_module, constant_name)
      end

      spies.size > 1 ? spies : spies.first
    end

    private

    def create_and_hook_spy(base_object, method_name, opts = {})
      case method_name
      when String, Symbol
        Subroutine.new(base_object, method_name).hook(opts)
      when Hash
        method_name.map do |name, result|
          create_and_hook_spy(base_object, name, opts).and_return(result)
        end
      else
        raise ArgumentError.new "#{method_name.class} is an invalid input, #on only accepts String, Symbol, and Hash"
      end
    end
  end
end
