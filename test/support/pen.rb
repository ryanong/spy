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

  def write_hash(**params)
    params.each do |p|
      write(p.join(':'))
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

  def opt_kwargs(required, opt: nil, opt2: nil)
    [required, opt: opt, opt2: opt2]
  end

  def keyrest(**kwargs)
    kwargs
  end

  def req_kwargs(req1:, req2:)
    [req1, req2]
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

Pen.define_singleton_method(:meta_class_method) do
  "meta_class_method".freeze
end

Pen.send(:define_method, :meta_method) do
  "meta_method".freeze
end

