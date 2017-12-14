# Common initialization code used by Rspec and the performance testing script.

require "bundler/setup"
require "pry"
require "active_record"
require "active_support"
require "mysql2"
require "cuddlefish"
require "database_cleaner"

ENV["RAILS_ENV"] ||= "test"
DatabaseCleaner.strategy = :truncation

def shard_specifications
  {
    test: [
      { tags: ["foo", "feline", "canine"],
        name: :shard_1,
        host: ENV["TEST_MYSQL_HOST"] || "localhost",
        port: ENV["TEST_MYSQL_PORT"] || 9506,
        username: ENV["TEST_MYSQL_USER"] || "root",
        password: ENV["TEST_MYSQL_PASSWORD"],
        adapter: "mysql2",
        database: "foo_db",
      },
      { tags: ["bar", "feline", "canine"],
        name: :shard_2,
        host: ENV["TEST_MYSQL_HOST"] || "localhost",
        port: ENV["TEST_MYSQL_PORT"] || 9506,
        username: ENV["TEST_MYSQL_USER"] || "root",
        password: ENV["TEST_MYSQL_PASSWORD"],
        adapter: "mysql2",
        database: "bar_db",
      },
      { tags: ["honk"],
        name: :the_mighty_honk,
        host: ENV["TEST_MYSQL_HOST"] || "localhost",
        port: ENV["TEST_MYSQL_PORT"] || 9506,
        username: ENV["TEST_MYSQL_USER"] || "root",
        password: ENV["TEST_MYSQL_PASSWORD"],
        adapter: "mysql2",
        database: "honk_db",
      },
    ],
  }.with_indifferent_access
end

def setup
  Cuddlefish.setup(shard_specifications)
end

def cleanup
  Cuddlefish.each_shard do
    DatabaseCleaner.clean
  end
end

def rebuild_schema
  @cleanup_client ||= begin
    cleanup_config = shard_specifications.dig(:test, 0).slice(:host, :port, :username, :password)
    Mysql2::Client.new(cleanup_config.merge(flags: Mysql2::Client::MULTI_STATEMENTS))
  end

  @schema_statements ||= begin
    schema = File.read("#{File.dirname(__FILE__)}/db_setup.sql")
    schema.split(";").map(&:strip).reject(&:empty?)
  end

  @schema_statements.each {|statement| @cleanup_client.query(statement) }
end

module Cuddlefish
  class Cat < ::ActiveRecord::Base
    set_shard_tags :feline
  end

  class Dog < ::ActiveRecord::Base
    set_shard_tags :canine
  end

  class Gouda < ::ActiveRecord::Base
    # doesn't have any tags
  end
end
