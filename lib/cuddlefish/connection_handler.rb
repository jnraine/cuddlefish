# This class subclasses the ActiveRecord ConnectionHandler object and
# overrides a couple of key methods to control how we look up
# ConnectionPools. We make it the default connection handler for all
# ActiveRecords in lib/cuddlefish.rb.

module Cuddlefish
  class TooManyMatchingConnections < Error; end
  class NoMatchingConnections < Error; end

  class ConnectionHandler < ::ActiveRecord::ConnectionAdapters::ConnectionHandler
    extend Helpers

    attr_reader :tags_for_pool

    def initialize
      @tags_for_pool = new_thread_safe_hash
      super
      Cuddlefish.shards.each do |shard|
        if self.class.rails_4?
          establish_connection(nil, shard.connection_spec)
        else
          establish_connection(shard.connection_spec)
        end
      end
    end

    def connection_pool_list
      tags_for_pool.keys
    end

    def connection_pools_for_class(klass)
      desired_tags = all_tags(klass)
      tags_for_pool.keys.select { |pool| (desired_tags - tags_for_pool[pool]).empty? }
    end

    def retrieve_connection_pool(klass)
      pools = connection_pools_for_class(klass)
      case pools.count
      when 0
        raise NoMatchingConnections.new("Found no connections matching #{all_tags(klass).inspect}")
      when 1
        pools.first
      else
        raise TooManyMatchingConnections.new("Found #{pools.count} connections matching #{all_tags(klass).inspect}")
      end
    end

    def remove_connection(owner)
      if pool = retrieve_connection_pool(owner)
        tags_for_pool.delete(pool)
        pool.disconnect!
        pool.spec.config
      end
    end

    # The arguments to this method changed between Rails 4.2 and 5.0.
    if rails_4?
      def establish_connection(_owner, spec)
        pool = ::ActiveRecord::ConnectionAdapters::ConnectionPool.new(spec)
        tags_for_pool[pool] = (spec.config[:tags] || [])
        pool
      end
    else
      def establish_connection(spec)
        pool = super(spec)
        tags_for_pool[pool] = (spec.config[:tags] || [])
        pool
      end
    end

    # The utility class for thread-safe hashes changed between Rails 4 and 5.
    def new_thread_safe_hash
      capacity = Cuddlefish.shards.count
      klass = self.class.rails_4? ? ThreadSafe::Cache : Concurrent::Map
      klass.new(initial_capacity: capacity)
    end

    def all_tags(klass)
      tags = Cuddlefish.current_shard_tags
      tags = (tags | klass.shard_tags) if !Thread.current[Cuddlefish::CLASS_TAGS_DISABLED_KEY]
      tags
    end
  end
end
