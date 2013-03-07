module Spy
  class Error < StandardError; end

  class AlreadyStubbedError < Error
    def message
      "Spy is already stubbed."
    end
  end

  class AlreadyHookedError < Error
    def message
      "Spy is already hooked."
    end
  end

  class NotHookedError < Error
    def message
      "Spy was not hooked."
    end
  end

  class NeverHookedError < Error
    def message
      "Spy was never hooked."
    end
  end

  class NoSpyError < Error
    def message
      "Spy could not be found"
    end
  end
end
