require 'spec_helper'

describe "Double" do
  let(:test_double) { double }

  specify "when one example has an expectation inside the block passed to should_receive" do
    Spy.stub(test_double, :msg).and_return do |arg|
      expect(arg).to be_true #this call exposes the problem
    end
    begin
      test_double.msg(false)
    rescue Exception
    end
  end

  specify "then the next example should behave as expected instead of saying" do
    test_double_spy = Spy.stub(test_double, :foobar)
    test_double.foobar
    expect(test_double_spy).to have_been_called
    test_double.foobar
    expect(test_double_spy.calls.count).to equal(2)
  end
end

