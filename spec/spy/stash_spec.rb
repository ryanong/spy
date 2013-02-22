require 'spec_helper'

module Spy
  describe "only stashing the original method" do
    let(:klass) do
      Class.new do
        def self.foo(arg)
          :original_value
        end
      end
    end

    it "keeps the original method intact after multiple expectations are added on the same method" do
      spy = Spy.on(klass, :foo)
      klass.foo(:bazbar)
      expect(spy).to have_been_called
      Spy.off(klass, :foo)

      expect(klass.foo(:yeah)).to equal(:original_value)
    end
  end

  describe "when a class method is aliased on a subclass and the method is mocked" do
    let(:klass) do
      Class.new do
        class << self
          alias alternate_new new
        end
      end
    end

    it "restores the original aliased public method" do
      klass = Class.new do
        class << self
          alias alternate_new new
        end
      end

      spy = Spy.on(klass, :alternate_new)
      expect(klass.alternate_new).to be_nil
      expect(spy).to have_been_called

      Spy.off(klass, :alternate_new)
      expect(klass.alternate_new).to be_an_instance_of(klass)
    end
  end
end
