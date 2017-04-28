require "rubygems"
require "bundler/setup"
require "pry"
require "active_record"
require "active_support"
require "mysql2"

require "database_cleaner"
DatabaseCleaner.strategy = :truncation

require "simplecov"
SimpleCov.start

require "cuddlefish"

RSpec.configure do |config|
  config.include Cuddlefish::Helpers

  config.before(:all) do
    specs = {
      shards: [
        { tags: ["foo", "feline", "canine"],
          host: ENV["TEST_MYSQL_HOST"] || "localhost",
          port: ENV["TEST_MYSQL_PORT"] || 9506,
          username: ENV["TEST_MYSQL_USER"] || "root",
          password: ENV["TEST_MYSQL_PASSWORD"],
          adapter: "mysql2",
          database: "foo_db",
        },
        { tags: ["bar", "feline", "canine"],
          host: ENV["TEST_MYSQL_HOST"] || "localhost",
          port: ENV["TEST_MYSQL_PORT"] || 9506,
          username: ENV["TEST_MYSQL_USER"] || "root",
          password: ENV["TEST_MYSQL_PASSWORD"],
          adapter: "mysql2",
          database: "bar_db",
        },
        { tags: ["honk"],
          host: ENV["TEST_MYSQL_HOST"] || "localhost",
          port: ENV["TEST_MYSQL_PORT"] || 9506,
          username: ENV["TEST_MYSQL_USER"] || "root",
          password: ENV["TEST_MYSQL_PASSWORD"],
          adapter: "mysql2",
          database: "honk_db",
        },
      ],
    }.with_indifferent_access
    Cuddlefish.setup(specs)
  end

  config.before(:each) do
    Cuddlefish.each_shard do
      DatabaseCleaner.clean
    end
  end
end

ActiveRecord::Base.include(Cuddlefish::ActiveRecord)

module Cuddlefish
  class Cat < ::ActiveRecord::Base
    set_shard_tags :feline
  end
end

module Cuddlefish
  class Dog < ::ActiveRecord::Base
    set_shard_tags :canine
  end
end

module Cuddlefish
  class Gouda < ::ActiveRecord::Base
    # doesn't have any tags
  end
end
