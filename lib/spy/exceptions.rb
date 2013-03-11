module Spy
  class Error < StandardError; end

  class AlreadyStubbedError < Error
    def to_s
      @mesg || "Spy is already stubbed."
    end
  end

  class AlreadyHookedError < Error
    def to_s
      @mesg || "Spy is already hooked."
    end
  end

  class NotHookedError < Error
    def to_s
      @mesg || "Spy was not hooked."
    end
  end

  class NeverHookedError < Error
    def to_s
      @mesg || "Spy was never hooked."
    end
  end

  class NoSpyError < Error
    def to_s
      @mesg || "Spy could not be found"
    end
  end
end
