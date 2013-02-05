require 'spec_helper'

module RSpec
  module Mocks
    describe "stub implementation" do
      describe "with no args" do
        it "execs the block when called" do
          obj = stub()
          Spy.stub(obj, :foo).and_return { :bar }
          expect(obj.foo).to eq :bar
        end
      end

      describe "with one arg" do
        it "execs the block with that arg when called" do
          obj = stub()
          Spy.stub(obj, :foo).and_return {|given| given}
          expect(obj.foo(:bar)).to eq :bar
        end
      end

      describe "with variable args" do
        it "execs the block when called" do
          obj = stub()
          Spy.stub(obj, :foo).and_return {|*given| given.first}
          expect(obj.foo(:bar)).to eq :bar
        end
      end
    end


    describe "unstub implementation" do
      it "replaces the stubbed method with the original method" do
        obj = Object.new
        def obj.foo; :original; end
        Spy.stub(obj, :foo)
        Spy.off(obj, :foo)
        expect(obj.foo).to eq :original
      end

      it "restores the correct implementations when stubbed and unstubbed on a parent and child class" do
        parent = Class.new
        child  = Class.new(parent)

        Spy.stub(parent, :new)
        Spy.stub(child, :new)
        Spy.off(parent, :new)
        Spy.off(child, :new)

        expect(parent.new).to be_an_instance_of parent
        expect(child.new).to be_an_instance_of child
      end

      it "raises a MockExpectationError if the method has not been stubbed" do
        obj = Object.new
        expect {
          Spy.off(obj, :foo)
        }.to raise_error
      end
    end
  end
end
