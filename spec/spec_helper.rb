ENV["RAILS_ENV"] ||= "test"

require "rubygems"

require "simplecov"
SimpleCov.start

$: << "."
require "spec/init"

RSpec.configure do |config|
  config.include Cuddlefish::Helpers

  config.before(:each) do
    setup
    cleanup
  end

  config.after(:each) do
    Cuddlefish.stop
  end
end
