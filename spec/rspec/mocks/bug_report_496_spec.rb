require 'spec_helper'

module BugReport496
  describe "a message expectation on a base class object" do
    class BaseClass
    end

    class SubClass < BaseClass
    end

    it "is received" do
      new_spy = Spy.on(BaseClass, :new)
      SubClass.new
      new_spy.calls.count.should == 1
    end
  end
end

