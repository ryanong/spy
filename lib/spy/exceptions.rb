module Spy
  Error = Class.new(StandardError)
  AlreadyStubbedError = Class.new(Error)
  AlreadyHookedError = Class.new(Error)
  NotHookedError = Class.new(Error)
  NeverHookedError = Class.new(Error)
  NoSpyError = Class.new(Error)
end
