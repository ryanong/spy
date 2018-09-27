module Features
  extend self

  def keyword_args?
    Gem::Version.new(RUBY_VERSION) >= Gem::Version.new("2.0.0")
  end

  def required_keyword_args?
    Gem::Version.new(RUBY_VERSION) >= Gem::Version.new("2.1.0")
  end
end
