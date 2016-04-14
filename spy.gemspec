# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'spy/version'

Gem::Specification.new do |gem|
  gem.name          = "spy"
  gem.version       = Spy::VERSION
  gem.required_ruby_version = '>= 1.9.3'
  gem.license       = 'MIT'
  gem.authors       = ["Ryan Ong"]
  gem.email         = ["ryanong@gmail.com"]
  gem.summary       = %q{A simple modern mocking library that uses the spy pattern and checks method's existence and arity.}
  gem.description   = %q{Spy is a mocking library that was made for the modern age. It supports only 1.9.3+. Spy by default will raise an error if you attempt to stub a method that doesn't exist or call the stubbed method with the wrong arity.}
  gem.homepage      = "https://github.com/ryanong/spy"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
  gem.add_development_dependency('pry')
  gem.add_development_dependency('pry-nav')
  gem.add_development_dependency('minitest', '>= 4.5.0')
  gem.add_development_dependency('rspec-core')
  gem.add_development_dependency('rspec-expectations')
  gem.add_development_dependency('coveralls')
end
