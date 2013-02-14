module Spy
  class Constant
    attr_reader :constant_name, :calls
    NIL_PROC = Proc.new { nil }
    def initialize(base_module, constant_name)
      @base_module, @constant_name = base_module, constant_name
      @calls = 0
      @plan = NIL_PROC
    end

    def hook
      Nest.get(base_module).hook(self)
    end

    def unhook
      Nest.get(base_module).hook(self)
    end

    def and_hide
      @plan = Proc.new { super }
      self
    end

    def and_show
      @hidden = NIL_PROC
      self
    end

    def and_return(value)
      @plan = Proc.new { value }
      self
    end

    def invoke
      @calls += 1
      @plan
    end
  end
end
