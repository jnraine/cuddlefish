require "cuddlefish/error"
require "cuddlefish/helpers"
require "cuddlefish/active_record"
require "cuddlefish/connection_handler"
require "cuddlefish/shard"
require "cuddlefish/version"

module Cuddlefish
  THREAD_LOCAL_KEY = "Cuddlefish v#{Cuddlefish::VERSION} shard tags".freeze

  mattr_reader(:shards) { Array.new }

  def self.load_config_file(filename)
    setup(YAML.load_file(filename))
  end

  def self.setup(db_specs)
    db_specs["shards"].each { |spec| add_shard(spec) }
    ::ActiveRecord::Base.default_connection_handler = Cuddlefish::ConnectionHandler.new
  end

  def self.current_shard_tags
    Thread.current[THREAD_LOCAL_KEY] ||= []
  end

  # FIXME: SLOOOOOOOW. (Thought: Use a Set instead of an Array.)
  def self.with_shard_tags(*tags)
    old_tags = current_shard_tags
    Thread.current[THREAD_LOCAL_KEY] = (old_tags | tags.flatten)
    yield
    Thread.current[THREAD_LOCAL_KEY] = old_tags
  end

  def self.with_exact_shard_tags(*tags)
    raise ArgumentError.new("No tags specified for with_exact_shard_tags!") if tags.empty?
    old_tags = current_shard_tags
    Thread.current[THREAD_LOCAL_KEY] = tags.flatten
    yield
    Thread.current[THREAD_LOCAL_KEY] = old_tags
  end

  def self.each_tag(*tags)
    tags.flatten.each do |tag|
      with_shard_tags(tag) do
        yield
      end
    end
  end

  def self.each_shard(*tags)
    shards.each do |shard|
      with_exact_shard_tags(shard.tags) do
        yield
      end
    end
  end

  private

  # FIXME: NO LONGER TRUE. REMOVE THIS.
  # This is also used to set up some specs, so it's broken out into a separate method.
  def self.add_shard(spec)
    @@shards << Cuddlefish::Shard.new(HashWithIndifferentAccess.new(spec))
  end
end
