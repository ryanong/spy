# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'spy/version'

Gem::Specification.new do |gem|
  gem.name          = "spy"
  gem.version       = Spy::VERSION
  gem.authors       = ["Ryan Ong"]
  gem.email         = ["ryanong@gmail.com"]
  gem.description   = %q{A simple mocking library that doesn't spies your intelligence.}
  gem.summary       = %q{A simple non destructive mocking library.}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
  gem.add_development_dependency('minitest', '>= 4.5.0')
end
