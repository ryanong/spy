require 'spec_helper'

module Bug7611
  describe "A Partial Mock" do
    class Foo; end
    class Bar < Foo; end

    it "respects subclasses" do
      Spy.on(Foo, :new).and_return(Object.new)
    end

    it "should" do
      expect(Bar.new.class).to eq Bar
    end
  end
end
