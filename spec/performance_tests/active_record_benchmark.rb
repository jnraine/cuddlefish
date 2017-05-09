#!/usr/bin/env ruby

$: << "."
require "rubygems"
require "bundler/setup"
require "pry"
require "active_record"
require "active_support"
require "mysql2"
require "database_cleaner"

DatabaseCleaner.strategy = :truncation

$counter = 0
$start = Time.now.to_f
$iterations = ARGV[0] || 50_000

def progress(i)
  elapsed = Time.now.to_f - $start
  printf "\r[%d:%02d.%03d] Finished %d of #{$iterations} iterations (%.1f%%)... ",
    (elapsed / 60).floor, (elapsed % 60).floor, (elapsed % 1) * 1000,
    i + 1, (i + 1).to_f / $iterations * 100
end

def unique_name(type)
  "#{type}-#{$counter += 1}"
end

module Cuddlefish
  class Cat < ::ActiveRecord::Base
    establish_connection({
      host: ENV["TEST_MYSQL_HOST"] || "localhost",
      port: ENV["TEST_MYSQL_PORT"] || 9506,
      username: ENV["TEST_MYSQL_USER"] || "root",
      password: ENV["TEST_MYSQL_PASSWORD"],
      adapter: "mysql2",
      database: "foo_db",
    })
  end

  class Dog < ::ActiveRecord::Base
    establish_connection({
      host: ENV["TEST_MYSQL_HOST"] || "localhost",
      port: ENV["TEST_MYSQL_PORT"] || 9506,
      username: ENV["TEST_MYSQL_USER"] || "root",
      password: ENV["TEST_MYSQL_PASSWORD"],
      adapter: "mysql2",
      database: "bar_db",
    })
  end

  class Gouda < ::ActiveRecord::Base
    establish_connection({
      host: ENV["TEST_MYSQL_HOST"] || "localhost",
      port: ENV["TEST_MYSQL_PORT"] || 9506,
      username: ENV["TEST_MYSQL_USER"] || "root",
      password: ENV["TEST_MYSQL_PASSWORD"],
      adapter: "mysql2",
      database: "honk_db",
    })
  end
end

$iterations.times do |i|
  Cuddlefish::Cat.create!(name: unique_name(:cat))
  Cuddlefish::Dog.create!(name: unique_name(:dog))
  Cuddlefish::Cat.create!(name: unique_name(:cat))
  Cuddlefish::Dog.create!(name: unique_name(:dog))
  Cuddlefish::Gouda.create!(name: unique_name(:gouda))

  # The Cuddlefish benchmarks test the error-throwing stuff, so we should
  # just throw some fake errors to be roughly comparable.
  2.times do
    begin
      raise NotImplementedError
    rescue NotImplementedError
      # whatever...
    end
  end

  progress(i)
end

puts "done."
Cuddlefish::Cat.delete_all
Cuddlefish::Dog.delete_all
Cuddlefish::Gouda.delete_all
