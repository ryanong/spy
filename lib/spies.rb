require "spies/version"
require "spies/spy"
require "spies/dsl"

module Spies
  class << self
    Spy.singleton_methods.each do |method_name|
      define_method(method_name) do |*args|
        Spy.send(method_name, *args)
      end
    end
  end
end
