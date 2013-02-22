require 'spec_helper'

module Spy
  describe "using a Partial Mock," do

    def stub(object, method_name)
      Spy::Subroutine.new(object, method_name).hook(force: true)
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

    it "uses reports nil in the error message" do
      allow_message_expectations_on_nil

      _nil = nil
      spy = stub(_nil, :foobar)
      _nil.foobar
      expect(spy).to have_been_called
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
