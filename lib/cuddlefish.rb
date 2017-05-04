require "cuddlefish/error"
require "cuddlefish/helpers"
require "cuddlefish/active_record"
require "cuddlefish/connection_handler"
require "cuddlefish/shard"
require "cuddlefish/version"

module Cuddlefish
  THREAD_LOCAL_KEY = :"Cuddlefish v#{Cuddlefish::VERSION} shard tags"

  mattr_reader(:shards) { Array.new }

  # Loads the shards config file and hooks Cuddlefish into ActiveRecord.
  def self.start(filename)
    setup(YAML.load_file(filename))
  end

  def self.setup(db_specs)
    db_specs["shards"].each do |spec|
      @@shards << Cuddlefish::Shard.new(HashWithIndifferentAccess.new(spec))
    end
    ::ActiveRecord::Base.default_connection_handler = Cuddlefish::ConnectionHandler.new
  end

  def self.current_shard_tags
    Thread.current[THREAD_LOCAL_KEY] ||= []
  end

  # Restricts all ActiveRecord queries inside the block to shards which
  # match all of the tags in "tags".
  # FIXME: SLOOOOOOOW. (Thought: Use a Set instead of an Array.)
  def self.with_shard_tags(*tags)
    old_tags = current_shard_tags
    Thread.current[THREAD_LOCAL_KEY] = (old_tags | tags.flatten)
    yield
  ensure
    Thread.current[THREAD_LOCAL_KEY] = old_tags
  end

  # Restricts all ActiveRecord queries inside the block to shards which
  # match only the tags in "tags" (and any model-specific tags), ignoring
  # the restrictions imposed by any enclosing `with_shard_tags` calls.
  def self.with_exact_shard_tags(*tags)
    raise ArgumentError.new("No tags specified for with_exact_shard_tags!") if tags.empty?
    old_tags = current_shard_tags
    Thread.current[THREAD_LOCAL_KEY] = tags.flatten
    yield
  ensure
    Thread.current[THREAD_LOCAL_KEY] = old_tags
  end

  # Executes the block repeatedly, once for each tag you give it. Each time
  # it's wrapped in a `with_shard_tags` call for that individual tag.
  def self.each_tag(*tags)
    tags.flatten.each do |tag|
      with_shard_tags(tag) do
        yield
      end
    end
  end

  # Executes the block repeatedly, once for each shard defined in your
  # shards.yml. Each time, all queries within the block will be directed to a
  # particular database shard.
  def self.each_shard(*tags)
    shards.each do |shard|
      with_exact_shard_tags(shard.tags) do
        yield
      end
    end
  end
end
