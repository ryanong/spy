require 'bundler/setup'
require 'pry'
require 'pry-byebug'
require 'minitest/autorun'
require "minitest/reporters"
require 'coveralls'
Coveralls.wear!
Minitest::Reporters.use!

require 'spy'

Dir.glob(File.expand_path("../support/*", __FILE__)).each do |file|
  require file
end
