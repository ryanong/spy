require 'spec_helper'

module Spy
  describe "#any_instance" do
    class CustomErrorForAnyInstanceSpec < StandardError;end

    let(:klass) do
      Class.new do
        def existing_method; :existing_method_return_value; end
        def existing_method_with_arguments(arg_one, arg_two = nil); :existing_method_with_arguments_return_value; end
        def another_existing_method; end
        private
        def private_method; :private_method_return_value; end
      end
    end
    let(:existing_method_return_value){ :existing_method_return_value }

    context "with #stub" do
      it "does not suppress an exception when a method that doesn't exist is invoked" do
        Spy.on_instance_method(klass, :existing_method)
        expect { klass.new.bar }.to raise_error(NoMethodError)
      end

      context 'multiple methods' do
        it "allows multiple methods to be stubbed in a single invocation" do
          Spy.on_instance_method(klass, :existing_method => 'foo', :another_existing_method => 'bar')
          instance = klass.new
          expect(instance.existing_method).to eq('foo')
          expect(instance.another_existing_method).to eq('bar')
        end
      end

      context "behaves as 'every instance'" do
        it "stubs every instance in the spec" do
          Subroutine.new(klass, :foo, false).hook(force: true).and_return(result = Object.new)
          expect(klass.new.foo).to eq(result)
          expect(klass.new.foo).to eq(result)
        end

        it "stubs instance created before any_instance was called" do
          instance = klass.new
          Spy.on_instance_method(klass, :existing_method).and_return(result = Object.new)
          expect(instance.existing_method).to eq(result)
        end
      end

      context "with #and_return" do
        it "stubs a method that doesn't exist" do
          Spy.on_instance_method(klass, :existing_method).and_return(1)
          expect(klass.new.existing_method).to eq(1)
        end

        it "stubs a method that exists" do
          Spy.on_instance_method(klass, :existing_method).and_return(1)
          expect(klass.new.existing_method).to eq(1)
        end

        it "returns the same object for calls on different instances" do
          return_value = Object.new
          Spy.on_instance_method(klass, :existing_method).and_return(return_value)
          expect(klass.new.existing_method).to be(return_value)
          expect(klass.new.existing_method).to be(return_value)
        end
      end

      context "with #and_yield" do
        it "yields the value specified" do
          yielded_value = Object.new
          Spy.on_instance_method(klass, :existing_method).and_yield(yielded_value)
          klass.new.existing_method{|value| expect(value).to be(yielded_value)}
        end
      end

      context "with #and_raise" do
        it "stubs a method that doesn't exist" do
          Spy.on_instance_method(klass, :existing_method).and_raise(CustomErrorForAnyInstanceSpec)
          expect { klass.new.existing_method}.to raise_error(CustomErrorForAnyInstanceSpec)
        end

        it "stubs a method that exists" do
          Spy.on_instance_method(klass, :existing_method).and_raise(CustomErrorForAnyInstanceSpec)
          expect { klass.new.existing_method}.to raise_error(CustomErrorForAnyInstanceSpec)
        end
      end

      context "with a block" do
        it "stubs a method" do
          Spy.on_instance_method(klass, :existing_method) { 1 }
          expect(klass.new.existing_method).to eq(1)
        end

        it "returns the same computed value for calls on different instances" do
          Spy.on_instance_method(klass, :existing_method) { 1 + 2 }
          expect(klass.new.existing_method).to eq(klass.new.existing_method)
        end
      end

      context "core ruby objects" do
        it "works uniformly across *everything*" do
          Object.any_instance.stub(:foo).and_return(1)
          expect(Object.new.foo).to eq(1)
        end

        it "works with the non-standard constructor []" do
          Array.any_instance.stub(:foo).and_return(1)
          expect([].foo).to eq(1)
        end

        it "works with the non-standard constructor {}" do
          Hash.any_instance.stub(:foo).and_return(1)
          expect({}.foo).to eq(1)
        end

        it "works with the non-standard constructor \"\"" do
          String.any_instance.stub(:foo).and_return(1)
          expect("".foo).to eq(1)
        end

        it "works with the non-standard constructor \'\'" do
          String.any_instance.stub(:foo).and_return(1)
          expect(''.foo).to eq(1)
        end

        it "works with the non-standard constructor module" do
          Module.any_instance.stub(:foo).and_return(1)
          module RSpec::SampleRspecTestModule;end
          expect(RSpec::SampleRspecTestModule.foo).to eq(1)
        end

        it "works with the non-standard constructor class" do
          Class.any_instance.stub(:foo).and_return(1)
          class RSpec::SampleRspecTestClass;end
          expect(RSpec::SampleRspecTestClass.foo).to eq(1)
        end
      end
    end

    context "unstub implementation" do
      it "replaces the stubbed method with the original method" do
        Spy.on_instance_method(klass, :existing_method)
        klass.any_instance.unstub(:existing_method)
        expect(klass.new.existing_method).to eq(:existing_method_return_value)
      end

      it "removes all stubs with the supplied method name" do
        Spy.on_instance_method(klass, :existing_method).with(1)
        Spy.on_instance_method(klass, :existing_method).with(2)
        klass.any_instance.unstub(:existing_method)
        expect(klass.new.existing_method).to eq(:existing_method_return_value)
      end

      it "does not remove any expectations with the same method name" do
        klass.any_instance.should_receive(:existing_method_with_arguments).with(3).and_return(:three)
        Spy.on_instance_method(klass, :existing_method_with_arguments).with(1)
        Spy.on_instance_method(klass, :existing_method_with_arguments).with(2)
        klass.any_instance.unstub(:existing_method_with_arguments)
        expect(klass.new.existing_method_with_arguments(3)).to eq(:three)
      end

      it "raises a MockExpectationError if the method has not been stubbed" do
        expect {
          klass.any_instance.unstub(:existing_method)
        }.to raise_error(RSpec::Mocks::MockExpectationError, 'The method `existing_method` was not stubbed or was already unstubbed')
      end
    end

    context "with #should_receive" do
      let(:foo_expectation_error_message) { 'Exactly one instance should have received the following message(s) but didn\'t: foo' }
      let(:existing_method_expectation_error_message) { 'Exactly one instance should have received the following message(s) but didn\'t: existing_method' }

      context "with an expectation is set on a method which does not exist" do
        it "returns the expected value" do
          klass.any_instance.should_receive(:foo).and_return(1)
          expect(klass.new.foo(1)).to eq(1)
        end

        it "fails if an instance is created but no invocation occurs" do
          expect do
            klass.any_instance.should_receive(:foo)
            klass.new
            klass.rspec_verify
          end.to raise_error(RSpec::Mocks::MockExpectationError, foo_expectation_error_message)
        end

        it "fails if no instance is created" do
          expect do
            klass.any_instance.should_receive(:foo).and_return(1)
            klass.rspec_verify
          end.to raise_error(RSpec::Mocks::MockExpectationError, foo_expectation_error_message)
        end

        it "fails if no instance is created and there are multiple expectations" do
          expect do
            klass.any_instance.should_receive(:foo)
            klass.any_instance.should_receive(:bar)
            klass.rspec_verify
          end.to raise_error(RSpec::Mocks::MockExpectationError, 'Exactly one instance should have received the following message(s) but didn\'t: bar, foo')
        end

        it "allows expectations on instances to take priority" do
          klass.any_instance.should_receive(:foo)
          klass.new.foo

          instance = klass.new
          instance.should_receive(:foo).and_return(result = Object.new)
          expect(instance.foo).to eq(result)
        end

        context "behaves as 'exactly one instance'" do
          it "passes if subsequent invocations do not receive that message" do
            klass.any_instance.should_receive(:foo)
            klass.new.foo
            klass.new
          end

          it "fails if the method is invoked on a second instance" do
            instance_one = klass.new
            instance_two = klass.new
            expect do
              klass.any_instance.should_receive(:foo)

              instance_one.foo
              instance_two.foo
            end.to raise_error(RSpec::Mocks::MockExpectationError, "The message 'foo' was received by #{instance_two.inspect} but has already been received by #{instance_one.inspect}")
          end
        end

        context "normal expectations on the class object" do
          it "fail when unfulfilled" do
            expect do
              klass.any_instance.should_receive(:foo)
              klass.should_receive(:woot)
              klass.new.foo
              klass.rspec_verify
            end.to(raise_error(RSpec::Mocks::MockExpectationError) do |error|
              expect(error.message).not_to eq(existing_method_expectation_error_message)
            end)
          end


          it "pass when expectations are met" do
            klass.any_instance.should_receive(:foo)
            klass.should_receive(:woot).and_return(result = Object.new)
            klass.new.foo
            expect(klass.woot).to eq(result)
          end
        end
      end

      context "with an expectation is set on a method that exists" do
        it "returns the expected value" do
          klass.any_instance.should_receive(:existing_method).and_return(1)
          expect(klass.new.existing_method(1)).to eq(1)
        end

        it "fails if an instance is created but no invocation occurs" do
          expect do
            klass.any_instance.should_receive(:existing_method)
            klass.new
            klass.rspec_verify
          end.to raise_error(RSpec::Mocks::MockExpectationError, existing_method_expectation_error_message)
        end

        it "fails if no instance is created" do
          expect do
            klass.any_instance.should_receive(:existing_method)
            klass.rspec_verify
          end.to raise_error(RSpec::Mocks::MockExpectationError, existing_method_expectation_error_message)
        end

        it "fails if no instance is created and there are multiple expectations" do
          expect do
            klass.any_instance.should_receive(:existing_method)
            klass.any_instance.should_receive(:another_existing_method)
            klass.rspec_verify
          end.to raise_error(RSpec::Mocks::MockExpectationError, 'Exactly one instance should have received the following message(s) but didn\'t: another_existing_method, existing_method')
        end

        context "after any one instance has received a message" do
          it "passes if subsequent invocations do not receive that message" do
            klass.any_instance.should_receive(:existing_method)
            klass.new.existing_method
            klass.new
          end

          it "fails if the method is invoked on a second instance" do
            instance_one = klass.new
            instance_two = klass.new
            expect do
              klass.any_instance.should_receive(:existing_method)

              instance_one.existing_method
              instance_two.existing_method
            end.to raise_error(RSpec::Mocks::MockExpectationError, "The message 'existing_method' was received by #{instance_two.inspect} but has already been received by #{instance_one.inspect}")
          end
        end
      end
    end

    context "when resetting post-verification" do
      let(:space) { RSpec::Mocks::Space.new }

      context "existing method" do
        before(:each) do
          space.add(klass)
        end

        context "with stubbing" do
          context "public methods" do
            before(:each) do
              Spy.on_instance_method(klass, :existing_method).and_return(1)
              expect(klass.method_defined?(:__existing_method_without_any_instance__)).to be_true
            end

            it "restores the class to its original state after each example when no instance is created" do
              space.verify_all

              expect(klass.method_defined?(:__existing_method_without_any_instance__)).to be_false
              expect(klass.new.existing_method).to eq(existing_method_return_value)
            end

            it "restores the class to its original state after each example when one instance is created" do
              klass.new.existing_method

              space.verify_all

              expect(klass.method_defined?(:__existing_method_without_any_instance__)).to be_false
              expect(klass.new.existing_method).to eq(existing_method_return_value)
            end

            it "restores the class to its original state after each example when more than one instance is created" do
              klass.new.existing_method
              klass.new.existing_method

              space.verify_all

              expect(klass.method_defined?(:__existing_method_without_any_instance__)).to be_false
              expect(klass.new.existing_method).to eq(existing_method_return_value)
            end
          end

          context "private methods" do
            before :each do
              Spy.on_instance_method(klass, :private_method).and_return(:something)
              space.verify_all
            end

            it "cleans up the backed up method" do
              expect(klass.method_defined?(:__existing_method_without_any_instance__)).to be_false
            end

            it "restores a stubbed private method after the spec is run" do
              expect(klass.private_method_defined?(:private_method)).to be_true
            end

            it "ensures that the restored method behaves as it originally did" do
              expect(klass.new.send(:private_method)).to eq(:private_method_return_value)
            end
          end
        end

        context "with expectations" do
          context "private methods" do
            before :each do
              klass.any_instance.should_receive(:private_method).and_return(:something)
              klass.new.private_method
              space.verify_all
            end

            it "cleans up the backed up method" do
              expect(klass.method_defined?(:__existing_method_without_any_instance__)).to be_false
            end

            it "restores a stubbed private method after the spec is run" do
              expect(klass.private_method_defined?(:private_method)).to be_true
            end

            it "ensures that the restored method behaves as it originally did" do
              expect(klass.new.send(:private_method)).to eq(:private_method_return_value)
            end
          end

          context "ensures that the subsequent specs do not see expectations set in previous specs" do
            context "when the instance created after the expectation is set" do
              it "first spec" do
                klass.any_instance.should_receive(:existing_method).and_return(Object.new)
                klass.new.existing_method
              end

              it "second spec" do
                expect(klass.new.existing_method).to eq(existing_method_return_value)
              end
            end

            context "when the instance created before the expectation is set" do
              before :each do
                @instance = klass.new
              end

              it "first spec" do
                klass.any_instance.should_receive(:existing_method).and_return(Object.new)
                @instance.existing_method
              end

              it "second spec" do
                expect(@instance.existing_method).to eq(existing_method_return_value)
              end
            end
          end

          it "ensures that the next spec does not see that expectation" do
            klass.any_instance.should_receive(:existing_method).and_return(Object.new)
            klass.new.existing_method
            space.verify_all

            expect(klass.new.existing_method).to eq(existing_method_return_value)
          end
        end
      end

      context "with multiple calls to any_instance in the same example" do
        it "does not prevent the change from being rolled back" do
          Spy.on_instance_method(klass, :existing_method).and_return(false)
          Spy.on_instance_method(klass, :existing_method).and_return(true)

          klass.rspec_verify
          expect(klass.new).to respond_to(:existing_method)
          expect(klass.new.existing_method).to eq(existing_method_return_value)
        end
      end

      it "adds an class to the current space when #any_instance is invoked" do
        klass.any_instance
        expect(RSpec::Mocks::space.send(:receivers)).to include(klass)
      end

      it "adds an instance to the current space when stubbed method is invoked" do
        Spy.on_instance_method(klass, :foo)
        instance = klass.new
        instance.foo
        expect(RSpec::Mocks::space.send(:receivers)).to include(instance)
      end
    end

    context 'when used in conjunction with a `dup`' do
      it "doesn't cause an infinite loop" do
        Spy::Subroutine.new(Object, :some_method, false).hook(force: true)
        o = Object.new
        o.some_method
        expect { o.dup.some_method }.to_not raise_error(SystemStackError)
      end

      it "doesn't bomb if the object doesn't support `dup`" do
        klass = Class.new do
          undef_method :dup
        end
        Spy::Subroutine.new(Object, :some_method, false).hook(force: true)
      end

      it "doesn't fail when dup accepts parameters" do
        klass = Class.new do
          def dup(funky_option)
          end
        end

        Spy::Subroutine.new(Object, :some_method, false).hook(force: true)

        expect { klass.new.dup('Dup dup dup') }.to_not raise_error(ArgumentError)
      end
    end

    context "when directed at a method defined on a superclass" do
      let(:sub_klass) { Class.new(klass) }

      it "stubs the method correctly" do
        Spy.on_instance_method(klass, :existing_method).and_return("foo")
        expect(sub_klass.new.existing_method).to eq "foo"
      end

      it "mocks the method correctly" do
        instance_one = sub_klass.new
        instance_two = sub_klass.new
        expect do
          klass.any_instance.should_receive(:existing_method)
          instance_one.existing_method
          instance_two.existing_method
        end.to raise_error(RSpec::Mocks::MockExpectationError, "The message 'existing_method' was received by #{instance_two.inspect} but has already been received by #{instance_one.inspect}")
      end
    end

    context "when a class overrides Object#method" do
      let(:http_request_class) { Struct.new(:method, :uri) }

      it "stubs the method correctly" do
        http_request_class.any_instance.stub(:existing_method).and_return("foo")
        expect(http_request_class.new.existing_method).to eq "foo"
      end

      it "mocks the method correctly" do
        http_request_class.any_instance.should_receive(:existing_method).and_return("foo")
        expect(http_request_class.new.existing_method).to eq "foo"
      end
    end

    context "when used after the test has finished" do
      it "restores the original behavior of a stubbed method" do
        Spy.on_instance_method(klass, :existing_method).and_return(:stubbed_return_value)

        instance = klass.new
        expect(instance.existing_method).to eq :stubbed_return_value

        RSpec::Mocks.verify

        expect(instance.existing_method).to eq :existing_method_return_value
      end
    end
  end
end
