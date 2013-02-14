require 'spec_helper'

describe "Spy" do

  class Foo
    def method_that_accepts_a_block(&block)
    end
  end

  let(:obj) { Foo.new }

  describe "#and_yield" do
    context "with eval context as block argument" do

      it "evaluates the supplied block as it is read" do
        evaluated = false
        Spy.on(obj, :method_that_accepts_a_block).and_yield do |eval_context|
          evaluated = true
        end
        expect(evaluated).to be_true
      end

      it "passes an eval context object to the supplied block" do
        Spy.on(obj, :method_that_accepts_a_block).and_yield do |eval_context|
          expect(eval_context).not_to be_nil
        end
      end

      it "evaluates the block passed to the stubbed method in the context of the supplied eval context" do
        expected_eval_context = nil
        actual_eval_context = nil

        Spy.on(obj, :method_that_accepts_a_block).and_yield do |eval_context|
          expected_eval_context = eval_context
        end

        obj.method_that_accepts_a_block do
          actual_eval_context = self
        end

        expect(actual_eval_context).to equal(expected_eval_context)
      end

      context "and no yielded arguments" do

        it "passes when expectations set on the eval context are met" do
          configured_eval_context = nil
          context_foo_spy = nil
          Spy.on(obj, :method_that_accepts_a_block).and_yield do |eval_context|
            configured_eval_context = eval_context
            context_foo_spy = Spy::Subroutine.new(configured_eval_context, :foo).hook(force: true)
          end

          obj.method_that_accepts_a_block do
            foo
          end

          expect(context_foo_spy).to have_been_called
        end

        it "fails when expectations set on the eval context are not met" do
          configured_eval_context = nil
          context_foo_spy = nil
          Spy.on(obj, :method_that_accepts_a_block).and_yield do |eval_context|
            configured_eval_context = eval_context
            context_foo_spy = Spy::Subroutine.new(configured_eval_context, :foo).hook(force: true)
          end

          obj.method_that_accepts_a_block do
            # foo is not called here
          end

          expect(context_foo_spy).to_not have_been_called
        end

      end

      context "and yielded arguments" do

        it "passes when expectations set on the eval context and yielded arguments are met" do
          configured_eval_context = nil
          yielded_arg = Object.new
          context_foo_spy = nil
          Spy.on(obj, :method_that_accepts_a_block).and_yield(yielded_arg) do |eval_context|
            configured_eval_context = eval_context
            context_foo_spy = Spy::Subroutine.new(configured_eval_context, :foo).hook(force: true)
            Spy::Subroutine.new(yielded_arg, :bar).hook(force: true)
          end

          obj.method_that_accepts_a_block do |obj|
            obj.bar
            foo
          end

          expect(context_foo_spy).to have_been_called
          expect(Spy.get(yielded_arg, :bar)).to have_been_called
        end

        it "fails when expectations set on the eval context and yielded arguments are not met" do
          configured_eval_context = nil
          yielded_arg = Object.new
          context_foo_spy = nil
          Spy.on(obj, :method_that_accepts_a_block).and_yield(yielded_arg) do |eval_context|
            configured_eval_context = eval_context
            context_foo_spy = Spy::Subroutine.new(configured_eval_context, :foo).hook(force: true)
            Spy::Subroutine.new(yielded_arg, :bar).hook(force: true)
          end

          obj.method_that_accepts_a_block do |obj|
            # obj.bar is not called here
            # foo is not called here
          end

          expect(context_foo_spy).to_not have_been_called
          expect(Spy.get(yielded_arg, :bar)).to_not have_been_called
        end

      end

    end
  end
end

