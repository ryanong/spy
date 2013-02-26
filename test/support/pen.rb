class Pen
  attr_reader :written, :color

  def initialize(color = :black)
    @color = color
    @written = []
  end

  def write(string)
    @written << string
    string
  end

  def write_block(&block)
    string = yield
    @written << string
    string
  end

  def write_hello
    write("hello")
  end

  def write_array(*args)
    args.each do |arg|
      write(arg)
    end
  end

  def greet(hello = "hello", name)
    write("#{hello} #{name}")
  end

  def public_method
  end

  def another
    "another"
  end

  protected
  def protected_method
  end

  private
  def private_method
  end

  class << self
    def another
      "another"
    end

    def public_method
    end

    protected
    def protected_method
    end

    private
    def private_method
    end

  end
end

another = "meta_method"

Pen.define_singleton_method(:meta_method) do
  another
end

Pen.send(:define_method, :meta_method) do
  another
end

