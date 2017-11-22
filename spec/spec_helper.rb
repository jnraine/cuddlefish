module Rails
  def self.env
    "test"
  end
end

require "rubygems"

require "simplecov"
SimpleCov.start

$: << "."
require "spec/init"

RSpec.configure do |config|
  config.include Cuddlefish::Helpers
  config.before(:each) { cleanup }
end
