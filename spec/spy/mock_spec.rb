require 'spec_helper'

module Spy
  describe Double do
    before(:each) { @double = Spy.double("test double") }

    it "has method_missing as private" do
      expect(Spy.double("stuff").private_instance_methods).to include_method(:method_missing)
    end

    it "does not respond_to? method_missing (because it's private)" do
      expect(Spy.double("stuff")).not_to respond_to(:method_missing)
    end

    it "fails when receiving message specified as not to be received" do
      spy = Spy.on(@double, :not_expected)
      expect(spy).to_not have_been_called
    end

    it "fails if unexpected method called" do
      expect {
        @double.something("a","b","c")
      }.to raise_error
    end

    it "uses block for expectation if provided" do
      spy = Spy.on(@double, :something).and_return do | a, b |
        expect(a).to eq "a"
        expect(b).to eq "b"
        "booh"
      end
      expect(@double.something("a", "b")).to eq "booh"
      expect(spy).to have_been_called
    end

    it "fails if expectation block fails" do
      Spy.on(@double, :something).and_return do | bool|
        expect(bool).to be_true
      end

      expect {
        @double.something false
      }.to raise_error(RSpec::Expectations::ExpectationNotMetError)
    end

    it "passes proc to expectation block without an argument" do
      spy = Spy.on(@double, :foo).and_return do |&block|
        expect(block.call).to eq(:bar)
      end
      @double.foo { :bar }
      expect(spy).to have_been_called
    end

    it "passes proc to expectation block with an argument" do
      spy = Spy.on(@double, :foo).and_return do |arg, &block|
        expect(block.call).to eq(:bar)
      end
      @double.foo(:arg) { :bar }
      expect(spy).to have_been_called
    end

    it "passes proc to stub block without an argurment" do
      spy = Spy.on(@double, :foo).and_return do |&block|
        expect(block.call).to eq(:bar)
      end
      @double.foo { :bar }
      expect(spy).to have_been_called
    end

    it "passes proc to stub block with an argument" do
      spy = Spy.on(@double, :foo) do |arg, &block|
        expect(block.call).to eq(:bar)
      end
      @double.foo(:arg) { :bar }
      expect(spy).to have_been_called
    end

    it "fails right away when method defined as never is received" do
      Spy.on(@double, :not_expected).never
      expect { @double.not_expected }.
        to raise_error(RSpec::Mocks::MockExpectationError,
                       %Q|(Double "test double").not_expected(no args)\n    expected: 0 times\n    received: 1 time|
                      )
    end

    it "raises RuntimeError by default" do
      Spy.on(@double, :something).and_raise
      expect { @double.something }.to raise_error(RuntimeError)
    end

    it "raises RuntimeError with a message by default" do
      Spy.on(@double, :something).and_raise("error message")
      expect { @double.something }.to raise_error(RuntimeError, "error message")
    end

    it "raises an exception of a given type without an error message" do
      Spy.on(@double, :something).and_raise(StandardError)
      expect { @double.something }.to raise_error(StandardError)
    end

    it "raises an exception of a given type with a message" do
      Spy.on(@double, :something).and_raise(RuntimeError, "error message")
      expect { @double.something }.to raise_error(RuntimeError, "error message")
    end

    it "raises a given instance of an exception" do
      Spy.on(@double, :something).and_raise(RuntimeError.new("error message"))
      expect { @double.something }.to raise_error(RuntimeError, "error message")
    end

    class OutOfGas < StandardError
      attr_reader :amount, :units
      def initialize(amount, units)
        @amount = amount
        @units  = units
      end
    end

    it "raises a given instance of an exception with arguments other than the standard 'message'" do
      Spy.on(@double, :something).and_raise(OutOfGas.new(2, :oz))

      begin
        @double.something
        fail "OutOfGas was not raised"
      rescue OutOfGas => e
        expect(e.amount).to eq 2
        expect(e.units).to eq :oz
      end
    end

    it "throws when told to" do
      Spy.on(@double, :something).and_throw(:blech)
      expect {
        @double.something
      }.to throw_symbol(:blech)
    end

    it "returns value from block by default" do
      spy = Spy.on(@double, :method_that_yields).and_yield
      value = @double.method_that_yields { :returned_obj }
      expect(value).to eq :returned_obj
      expect(spy).to have_been_called
    end

    it "is able to raise from method calling yielding double" do
      spy = Spy.on(@double, :yield_me).and_yield 44

      expect {
        @double.yield_me do |x|
          raise "Bang"
        end
      }.to raise_error(StandardError, "Bang")

      expect(spy).to have_been_called
    end

    it "assigns stub return values" do
      double = Spy.double('name', :message => :response)
      expect(double.message).to eq :response
    end

  end

  describe "a double message receiving a block" do
    before(:each) do
      @double = Spy.double("double")
      @calls = 0
    end

    def add_call
      @calls = @calls + 1
    end

    it "calls the block after #should_receive" do
      spy = Spy.on(@double, :foo).and_return { add_call }

      @double.foo

      expect(@calls).to eq 1
      expect(spy).to have_been_called
    end
  end

  describe 'string representation generated by #to_s' do
    it 'does not contain < because that might lead to invalid HTML in some situations' do
      double = Spy.double("Dog")
      valid_html_str = "#{double}"
      expect(valid_html_str).not_to include('<')
    end
  end

  describe "string representation generated by #to_str" do
    it "looks the same as #to_s" do
      double = Spy.double("Foo")
      expect(double.to_str).to eq double.to_s
    end
  end

  describe "double created with no name" do
    it "does not use a name in a failure message" do
      double = Spy.double()
      expect {double.foo}.to raise_error(/Double received/)
    end

    it "does respond to initially stubbed methods" do
      double = Spy.double("name", :foo => "woo", :bar => "car")
      expect(double.foo).to eq "woo"
      expect(double.bar).to eq "car"
    end
  end

  describe "==" do
    it "sends '== self' to the comparison object" do
      first = Spy.double('first')
      second = Spy.double('second')

      spy = Spy.on(first, :==)
      second == first
      expect(spy.calls.first.args).to eq([second])
    end
  end
end
