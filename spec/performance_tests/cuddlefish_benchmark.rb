#!/usr/bin/env ruby

$: << "."
require "rubygems"
require "spec/init"

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

$iterations.times do |i|
  Cuddlefish.use_shard_tags(:foo) do
    Cuddlefish::Cat.create!(name: unique_name(:cat))
    Cuddlefish::Dog.create!(name: unique_name(:dog))
  end

  Cuddlefish.use_shard_tags(:bar) do
    Cuddlefish::Cat.create!(name: unique_name(:cat))
    Cuddlefish::Dog.create!(name: unique_name(:dog))
  end

  Cuddlefish.use_shard_tags(:honk) do
    Cuddlefish::Gouda.create!(name: unique_name(:gouda))
  end

  begin
    Cuddlefish.use_shard_tags(:feline, :honk) do
      Cuddlefish::Cat.count
    end
  rescue Cuddlefish::NoMatchingConnections
    # whatever...
  end

  begin
    Cuddlefish.use_shard_tags(:feline) do
      Cuddlefish::Cat.create!(name: unique_name(:cat))
    end
  rescue Cuddlefish::TooManyMatchingConnections
    # whatever...
  end

  progress(i)
end

puts "done."
cleanup
