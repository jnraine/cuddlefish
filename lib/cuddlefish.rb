require "cuddlefish/error"
require "cuddlefish/helpers"
require "cuddlefish/active_record"
require "cuddlefish/connection_handler"
require "cuddlefish/migrations"
require "cuddlefish/railtie"
require "cuddlefish/shard"
require "cuddlefish/shard_manager"
require "cuddlefish/version"

module Cuddlefish
  CURRENT_SHARD_TAGS_KEY = :"Cuddlefish v#{Cuddlefish::VERSION} shard tags"
  CLASS_TAGS_DISABLED_KEY = :"Cuddlefish v#{Cuddlefish::VERSION} class tags disabled"

  mattr_reader(:shard_manager) { Cuddlefish::ShardManager.new }
  mattr_accessor(:tags_for_migration) { lambda { |_| [] } }

  # Loads the shards config file and hooks Cuddlefish into ActiveRecord.
  def self.start(filename)
    setup(YAML.load_file(filename))
  end

  def self.setup(db_specs)
    # Create Shard objects for each of the shards in shards.yml.
    db_specs[Rails.env.to_s].each do |spec|
      shard_manager.add(spec)
    end

    # Replace the standard AR connection handler with our own.
    ::ActiveRecord::Base.default_connection_handler = Cuddlefish::ConnectionHandler.new

    # Load patches for specific gems.
    gem_dir = "#{File.dirname(__FILE__)}/cuddlefish/gem_patches"
    Dir.glob("#{gem_dir}/*.rb").each do |filename|
      gem_name = filename.sub(/.*\/(\S+)\.rb$/, '\1')
      require(filename) if Gem.loaded_specs.key?(gem_name)
    end
  end

  def self.shards
    shard_manager.shards
  end

  # Terminates all MySQL shard connections and forgets about all loaded shards.
  def self.stop
    each_shard do
      ::ActiveRecord::Base.default_connection_handler.remove_connection(::ActiveRecord::Base)
    end
    @@shard_manager = Cuddlefish::ShardManager.new
  end

  def self.current_shard_tags
    Thread.current[CURRENT_SHARD_TAGS_KEY] ||= []
  end

  # Restricts all ActiveRecord queries inside the block to shards which
  # match all of the tags in "tags".
  def self.use_shard_tags(*tags)
    raise ArgumentError.new("No tags specified for use_shard_tags!") if tags.empty?
    old_tags = current_shard_tags
    Thread.current[CURRENT_SHARD_TAGS_KEY] = (old_tags | tags.flatten)
    yield
  ensure
    Thread.current[CURRENT_SHARD_TAGS_KEY] = old_tags
  end

  # Restricts all ActiveRecord queries inside the block to shards which
  # match only the tags in "tags", ignoring the restrictions imposed by any
  # enclosing `use_shard_tags` calls or tags on models.
  def self.force_shard_tags(*tags)
    old_tags = current_shard_tags
    was_disabled = Thread.current[CLASS_TAGS_DISABLED_KEY]
    Thread.current[CURRENT_SHARD_TAGS_KEY] = tags.flatten
    Thread.current[CLASS_TAGS_DISABLED_KEY] = true
    yield
  ensure
    Thread.current[CURRENT_SHARD_TAGS_KEY] = old_tags
    Thread.current[CLASS_TAGS_DISABLED_KEY] = was_disabled
  end

  # Restricts all ActiveRecord queries inside the block to shards which
  # match only the tags in "tags" (and any model-specific tags), ignoring
  # the restrictions imposed by any enclosing `use_shard_tags` calls.
  def self.replace_shard_tags(*tags)
    old_tags = current_shard_tags
    Thread.current[CURRENT_SHARD_TAGS_KEY] = tags.flatten
    yield
  ensure
    Thread.current[CURRENT_SHARD_TAGS_KEY] = old_tags
  end

  def self.add_shard_tags(*tags)
    raise ArgumentError.new("No tags specified for add_shard_tags!") if tags.empty?
    Thread.current[CURRENT_SHARD_TAGS_KEY] = (current_shard_tags | tags.flatten)
  end

  def self.remove_shard_tags(*tags)
    raise ArgumentError.new("No tags specified for remove_shard_tags!") if tags.empty?
    Thread.current[CURRENT_SHARD_TAGS_KEY] = (current_shard_tags - tags.flatten)
  end

  # Executes the block repeatedly, once for each tag you give it. Each time
  # it's wrapped in a `use_shard_tags` call for that individual tag.
  # TO DO: Have it return an enumerator so we can chain `.map`, etc.
  def self.each_tag(*tags)
    tags.flatten.each do |tag|
      use_shard_tags(tag) do
        yield
      end
    end
  end

  # Executes the block repeatedly, once for each shard defined in your
  # shards.yml. Each time, all queries within the block will be directed to a
  # particular database shard.
  # TO DO: Have it return an enumerator. Then we could get rid of `map_shards`.
  def self.each_shard(*tags, &block)
    iterate_over_shards(:each, tags, &block)
  end

  # Same as each_shard, but returns an array of every iteration's results.
  def self.map_shards(*tags, &block)
    iterate_over_shards(:map, tags, &block)
  end

  private

  def self.iterate_over_shards(method, tags)
    shard_list = shard_manager.matching_connected_shards(tags.flatten)
    shard_list.public_send(method) do |shard|
      force_shard_tags(shard.tags) do
        yield
      end
    end
  end
end
