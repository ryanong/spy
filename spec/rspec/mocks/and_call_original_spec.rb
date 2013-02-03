require 'spec_helper'

describe "and_call_through" do
  context "on a partial mock object" do
    let(:klass) do
      Class.new do
        def meth_1
          :original
        end

        def meth_2(x)
          yield x, :additional_yielded_arg
        end

        def self.new_instance
          new
        end
      end
    end

    let(:instance) { klass.new }

    it 'passes the received message through to the original method' do
      Spy.on(instance, :meth_1).and_call_through
      expect(instance.meth_1).to eq(:original)
    end

    it 'passes args and blocks through to the original method' do
      Spy.on(instance, :meth_2).and_call_through
      value = instance.meth_2(:submitted_arg) { |a, b| [a, b] }
      expect(value).to eq([:submitted_arg, :additional_yielded_arg])
    end

    it 'works for singleton methods' do
      def instance.foo; :bar; end
      Spy.on(instance, :foo).and_call_through
      expect(instance.foo).to eq(:bar)
    end

    it 'works for methods added through an extended module' do
      instance.extend Module.new { def foo; :bar; end }
      Spy.on(instance, :foo).and_call_through
      expect(instance.foo).to eq(:bar)
    end

    it "works for method added through an extended module onto a class's ancestor" do
      sub_sub_klass = Class.new(Class.new(klass))
      klass.extend Module.new { def foo; :bar; end }
      Spy.on(sub_sub_klass, :foo).and_call_through
      expect(sub_sub_klass.foo).to eq(:bar)
    end

    it "finds the method on the most direct ancestor even if the method " +
       "is available on more distant ancestors" do
      klass.extend Module.new { def foo; :klass_bar; end }
      sub_klass = Class.new(klass)
      sub_klass.extend Module.new { def foo; :sub_klass_bar; end }
      Spy.on(sub_klass, :foo).and_call_through
      expect(sub_klass.foo).to eq(:sub_klass_bar)
    end

    it 'works for class methods defined on a superclass' do
      subclass = Class.new(klass)
      Spy.on(subclass, :new_instance).and_call_through
      expect(subclass.new_instance).to be_a(subclass)
    end

    it 'works for class methods defined on a grandparent class' do
      sub_subclass = Class.new(Class.new(klass))
      Spy.on(sub_subclass, :new_instance).and_call_through
      expect(sub_subclass.new_instance).to be_a(sub_subclass)
    end

    it 'works for class methods defined on the Class class' do
      Spy.on(klass, :new).and_call_through
      expect(klass.new).to be_an_instance_of(klass)
    end

    it "works for instance methods defined on the object's class's superclass" do
      subclass = Class.new(klass)
      inst = subclass.new
      Spy.on(inst, :meth_1).and_call_through
      expect(inst.meth_1).to eq(:original)
    end

    it 'works for aliased methods' do
      klass = Class.new do
        class << self
          alias alternate_new new
        end
      end

      Spy.on(klass, :alternate_new).and_call_through
      expect(klass.alternate_new).to be_an_instance_of(klass)
    end

    context 'on an object that defines method_missing' do
      before do
        klass.class_eval do
          private

          def method_missing(name, *args)
            if name.to_s == "greet_jack"
              "Hello, jack"
            else
              super
            end
          end
        end
      end

      it 'works when the method_missing definition handles the message' do
        Spy.on(instance, :greet_jack).and_call_through
        expect(instance.greet_jack).to eq("Hello, jack")
      end

      it 'raises an error on invocation if method_missing does not handle the message' do
        Spy.on(instance, :not_a_handled_message).and_call_through

        # Note: it should raise a NoMethodError (and usually does), but
        # due to a weird rspec-expectations issue (see #183) it sometimes
        # raises a `NameError` when a `be_xxx` predicate matcher has been
        # recently used. `NameError` is the superclass of `NoMethodError`
        # so this example will pass regardless.
        # If/when we solve the rspec-expectations issue, this can (and should)
        # be changed to `NoMethodError`.
        expect {
          instance.not_a_handled_message
        }.to raise_error(NameError, /not_a_handled_message/)
      end
    end
  end

  context "on a partial mock object that overrides #method" do
    let(:request_klass) do
      Struct.new(:method, :url) do
        def perform
          :the_response
        end

        def self.method
          :some_method
        end
      end
    end

    let(:request) { request_klass.new(:get, "http://foo.com/bar") }

    it 'still works even though #method has been overriden' do
      Spy.on(request, :perform).and_call_through
      expect(request.perform).to eq(:the_response)
    end

    it 'works for a singleton method' do
      def request.perform
        :a_response
      end

      Spy.on(request, :perform).and_call_through
      expect(request.perform).to eq(:a_response)
    end
  end

  context "on a pure mock object" do
    let(:instance) { double }

    it 'raises an error even if the mock object responds to the message' do
      expect(instance.to_s).to be_a(String)
      mock_expectation = Spy.on(instance, :to_s)
      instance.to_s # to satisfy the expectation

      expect {
        mock_expectation.and_call_through
      }.to raise_error(/and_call_through.*partial mock/i)
    end
  end
end

