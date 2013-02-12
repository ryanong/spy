require 'spec_helper'

class Spy
  describe "using a Partial Mock," do

    def stub(object, method_name)
      Spy.new(object, method_name).hook(force: true)
    end

    let(:object) { Object.new }

    it "names the class in the failure message" do
      spy = stub(object, :foo)
      expect(spy).to_not have_been_called
    end

    it "names the class in the failure message when expectation is on class" do
      spy = stub(Object, :foo)
      expect(spy).to_not have_been_called
    end

    it "does not conflict with @options in the object" do
      object.instance_eval { @options = Object.new }
      spy = stub(object, :blah)
      object.blah
      expect(spy).to have_been_called
    end

    it "should_receive mocks out the method" do
      stub(object, :foobar).with(:test_param).and_return(1)
      expect(object.foobar(:test_param)).to equal(1)
    end

    it "should_receive handles a hash" do
      stub(object, :foobar).with(:key => "value").and_return(1)
      expect(object.foobar(:key => "value")).to equal(1)
    end

    it "should_receive handles an inner hash" do
      hash = {:a => {:key => "value"}}
      object.should_receive(:foobar).with(:key => "value").and_return(1)
      expect(object.foobar(hash[:a])).to equal(1)
    end

    it "should_receive returns a message expectation" do
      expect(object.should_receive(:foobar)).to be_kind_of(RSpec::Mocks::MessageExpectation)
      object.foobar
    end

    it "should_receive verifies method was called" do
      object.should_receive(:foobar).with(:test_param).and_return(1)
      expect {
        object.rspec_verify
      }.to raise_error(RSpec::Mocks::MockExpectationError)
    end

    it "should_receive also takes a String argument" do
      object.should_receive('foobar')
      object.foobar
    end

    it "should_not_receive also takes a String argument" do
      object.should_not_receive('foobar')
      expect {
        object.foobar
      }.to raise_error(RSpec::Mocks::MockExpectationError)
    end

    it "uses reports nil in the error message" do
      allow_message_expectations_on_nil

      _nil = nil
      _nil.should_receive(:foobar)
      expect {
        _nil.rspec_verify
      }.to raise_error(
        RSpec::Mocks::MockExpectationError,
        %Q|(nil).foobar(any args)\n    expected: 1 time\n    received: 0 times|
      )
    end

    it "includes the class name in the error when mocking a class method that is called an extra time with the wrong args" do
      klass = Class.new do
        def self.inspect
          "MyClass"
        end
      end

      klass.should_receive(:bar).with(1)
      klass.bar(1)

      expect {
        klass.bar(2)
      }.to raise_error(RSpec::Mocks::MockExpectationError, /MyClass/)
    end
  end

  describe "Using a partial mock on a proxy object", :if => defined?(::BasicObject) do
    let(:proxy_class) do
      Class.new(::BasicObject) do
        def initialize(target)
          @target = target
        end

        def proxied?
          true
        end

        def method_missing(*a)
          @target.send(*a)
        end
      end
    end

    let(:instance) { proxy_class.new(Object.new) }

    it 'works properly' do
      instance.should_receive(:proxied?).and_return(false)
      expect(instance).not_to be_proxied
    end
  end

  describe "Partially mocking an object that defines ==, after another mock has been defined" do
    before(:each) do
      stub("existing mock", :foo => :foo)
    end

    let(:klass) do
      Class.new do
        attr_reader :val
        def initialize(val)
          @val = val
        end

        def ==(other)
          @val == other.val
        end
      end
    end

    it "does not raise an error when stubbing the object" do
      o = klass.new :foo
      expect { Spy.on(o, :bar) }.not_to raise_error(NoMethodError)
    end
  end

  describe "Method visibility when using partial mocks" do
    def stub(o, method_name)
      Spy.on(o, method_name)
    end

    let(:klass) do
      Class.new do
        def public_method
          private_method
          protected_method
        end
        protected
        def protected_method; end
        private
        def private_method; end
      end
    end

    let(:object) { klass.new }

    it 'keeps public methods public' do
      spy = stub(object, :public_method)
      expect(object.public_methods).to include_method(:public_method)
      object.public_method
      expect(spy).to have_been_called
    end

    it 'keeps private methods private' do
      spy = stub(object, :private_method)
      expect(object.private_methods).to include_method(:private_method)
      object.public_method
      expect(spy).to have_been_called
    end

    it 'keeps protected methods protected' do
      spy = stub(object, :protected_method)
      expect(object.protected_methods).to include_method(:protected_method)
      object.public_method
      expect(spy).to have_been_called
    end

  end
end
