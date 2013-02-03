class Spy
  class Double
    def initialize(name, *args)
      @name = name
      Spy.on(self,*args)
    end
  end
end
