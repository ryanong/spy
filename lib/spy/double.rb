class Spy
  class Double
    def initialize(name, *args)
      if name.is_a?(Hash) && args.empty?
        args = [name]
        @name = nil
      else
        @name = name
      end

      if args.present?
        Spy.on(self,*args)
      end
    end
  end
end
