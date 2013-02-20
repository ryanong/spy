require 'spec_helper'

module RSpec
  module Mocks
    describe "a double _not_ acting as a null object" do
      before(:each) do
        @double = Spy.double('non-null object')
      end

      it "says it does not respond to messages it doesn't understand" do
        expect(@double).not_to respond_to(:foo)
      end

      it "says it responds to messages it does understand" do
        Spy.on(@double, :foo)
        expect(@double).to respond_to(:foo)
      end

      it "raises an error when interpolated in a string as an integer" do
        expect { "%i" % @double }.to raise_error(TypeError)
      end
    end

    describe "a double acting as a null object" do
      before(:each) do
        @double = Spy.double('null object').as_null_object
      end

      it "says it responds to everything" do
        expect(@double).to respond_to(:any_message_it_gets)
      end

      it "allows explicit stubs" do
        Spy.on(@double, :foo) { "bar" }
        expect(@double.foo).to eq("bar")
      end

      it "allows explicit expectation" do
        spy = Spy.on(@double, :something)
        @double.something
        expect(spy).to have_been_called
      end

      it 'continues to return self from an explicit expectation' do
        spy = Spy.on(@double, :bar)
        expect(@double.foo.bar).to be(@double)
        expect(spy).to have_been_called
      end

      it 'returns an explicitly stubbed value from an expectation with no implementation' do
        spy = Spy.on(@double, :foo => "bar")
        expect(@double.foo).to eq("bar")
        expect(spy).to have_been_called
      end

      it "can be interpolated in a string as an integer" do
        # This form of string interpolation calls
        # @double.to_int.to_int.to_int...etc until it gets an integer,
        # and thus gets stuck in an infinite loop unless our double
        # returns an int value from #to_int.
        expect(("%i" % @double)).to eq("0")
      end
    end

    describe "#as_null_object" do
      it "sets the object to null_object" do
        obj = Spy.double('anything').as_null_object
        expect(obj).to be_null_object
      end
    end

    describe "#null_object?" do
      it "defaults to false" do
        obj = Spy.double('anything')
        expect(obj).not_to be_null_object
      end
    end
  end
end
