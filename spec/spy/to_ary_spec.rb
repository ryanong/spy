require "spec_helper"

describe "a double receiving to_ary" do
  shared_examples "to_ary" do
    it "returns nil" do
      expect do
        expect(obj.to_ary).to be_nil
      end.to raise_error(NoMethodError)
    end

    it "doesn't respond" do
      expect(obj).not_to respond_to(:to_ary)
    end

    it "can be overridden with a stub" do
      Spy::Subroutine.new(obj, :to_ary).hook(force: true).and_return(:non_nil_value)
      expect(obj.to_ary).to be(:non_nil_value)
    end

    it "responds when overriden" do
      Spy::Subroutine.new(obj, :to_ary).hook(force: true).and_return(:non_nil_value)
      expect(obj).to respond_to(:to_ary)
    end

    it "supports Array#flatten" do
      obj = Spy.double('foo')
      expect([obj].flatten).to eq([obj])
    end
  end

  context "double as_null_object" do
    let(:obj) { Spy.double('obj').as_null_object }
    include_examples "to_ary"
  end

  context "double without as_null_object" do
    let(:obj) { Spy.double('obj') }
    include_examples "to_ary"
  end
end
