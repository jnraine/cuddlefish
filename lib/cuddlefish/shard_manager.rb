# A class which keeps track of all the user-defined shards and how they
# connect to their ActiveRecord connection pools.

module Cuddlefish
  class InvalidShardSpecification < StandardError; end

  class ShardManager
    attr_reader :shards

    def initialize
      @shards = []
      @shard_for_pool = {}   # FIXME: make this a thread-safe hash
    end

    # Creates & returns a new, disconnected shard based on the given specification.
    def add(spec)
      spec = spec.symbolize_keys
      validate_tags_present(spec)
      if spec[:name].nil? || spec[:name].empty?
        tags = spec[:tags].sort.join(",")
        spec[:name] = [*spec.values_at(:host, :database, :username), tags].join(":").freeze
      end
      validate_unique_name(spec[:name])
      @shards << Cuddlefish::Shard.new(spec)
      shards.last
    end

    # Returns the currently connected shards which match the given set of tags.
    def matching_connected_shards(desired_tags = [])
      shards = @shard_for_pool.values
      shards = shards.select { |shard| shard.matches?(desired_tags) } if !desired_tags.empty?
      shards
    end

    # Returns the shards which match the given set of tags.
    def matching_shards(desired_tags = [])
      shards.select { |shard| shard.matches?(desired_tags) }
    end

    # Returns the ActiveRecord connection pools for all connected shards.
    def all_connection_pools
      @shard_for_pool.keys
    end

    def find_by_name(name)
      shard = shards.find { |s| s.name == name }
      raise ArgumentError.new("Couldn't find a shard named #{name.inspect}!") if shard.nil?
      shard
    end

    def add_connection_pool(pool, shard)
      @shard_for_pool[pool] = shard
      shard.connection_pool = pool
    end

    def remove_connection_pool(pool)
      shard = @shard_for_pool.delete(pool)
      shard.connection_pool = nil
    end

    private

    def validate_tags_present(spec)
      if spec[:tags].nil? || spec[:tags].empty?
        name = spec[:name] || "#{spec[:host]}:#{spec[:database]}"
        raise InvalidShardSpecification.new("No tags for '#{name}' shard")
      end
    end

    def validate_unique_name(name)
      if shards.any? { |shard| shard.name == name }
        raise InvalidShardSpecification.new("Non-unique shard name: '#{name}'")
      end
    end
  end
end
