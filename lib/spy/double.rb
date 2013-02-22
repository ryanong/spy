module Spy
  class Double
    def initialize(name, *args)
      @name = name

      if args.size > 0
        Spy.on(self,*args)
      end
    end

    # @private
    def ==(other)
      other == self
    end

    # @private
    def inspect
      "#<#{self.class}:#{sprintf '0x%x', self.object_id} @name=#{@name.inspect}>"
    end

    # @private
    def to_s
      inspect.gsub('<','[').gsub('>',']')
    end

    alias_method :to_str, :to_s
  end
end
