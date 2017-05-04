require "rubygems"

require "simplecov"
SimpleCov.start

$: << "."
require "spec/init"

RSpec.configure do |config|
  config.include Cuddlefish::Helpers

  config.before(:all) { init_tests }
  config.before(:each) { cleanup }
end
