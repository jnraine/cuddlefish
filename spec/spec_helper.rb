require "rubygems"

require "simplecov"
SimpleCov.start

$: << "."
require "spec/init"

# Turn off migration output to STDOUT
ActiveRecord::Migration.verbose = false

RSpec.configure do |config|
  config.include Cuddlefish::Helpers

  config.before(:all) do
    setup
    rebuild_schema
    Cuddlefish.stop
  end

  config.before(:each) do
    setup
    cleanup
  end

  config.after(:each) do
    Cuddlefish.stop
  end
end
