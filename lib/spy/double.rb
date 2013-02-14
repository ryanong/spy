module Spy
  class Double
    def initialize(name, *args)
      @name = name

      if args.size > 0
        Spy.on(self,*args)
      end
    end
  end
end
