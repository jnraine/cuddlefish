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
    begin
      setup
      rebuild_schema
      Cuddlefish.stop
    rescue => e
      raise <<~ERROR
before(:all) raised an error

#{e.message}
#{e.backtrace.join("\n")}
      ERROR
    end
  end

  config.around do |example|
    setup
    cleanup
    example.run
    Cuddlefish.stop
  end
end
