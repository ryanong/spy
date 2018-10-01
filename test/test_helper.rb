require 'bundler/setup'
require 'minitest/autorun'
require "minitest/reporters"
require 'pry'
require 'pry-nav'
require 'coveralls'
Coveralls.wear!
Minitest::Reporters.use!

require 'spy'

Dir.glob(File.expand_path("../support/*", __FILE__)).each do |file|
  require file
end
