# This class subclasses the ActiveRecord ConnectionHandler object and
# overrides a couple of key methods to control how we look up
# ConnectionPools. We make it the default connection handler for all
# ActiveRecords in lib/cuddlefish.rb.

module Cuddlefish
  class TooManyMatchingConnections < Error; end
  class NoMatchingConnections < Error; end

  class ConnectionHandler < ::ActiveRecord::ConnectionAdapters::ConnectionHandler
    extend Helpers

    def initialize
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
      Cuddlefish.shard_manager.all_connection_pools
    end

    def connection_pools_for_class(klass)
      desired_tags = all_tags(klass)
      Cuddlefish.shard_manager.matching_connected_shards(desired_tags).map(&:connection_pool)
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
        Cuddlefish.shard_manager.remove_connection_pool(pool)
        pool.disconnect!
        pool.spec.config
      end
    end

    # The arguments to this method changed between Rails 4.2 and 5.0.
    if rails_4?
      def establish_connection(_owner, spec)
        shard = Cuddlefish.shard_manager.find_by_name(spec.config[:name])
        if !shard.connected?
          pool = ::ActiveRecord::ConnectionAdapters::ConnectionPool.new(spec)
          Cuddlefish.shard_manager.add_connection_pool(pool, shard)
        end
        shard.connection_pool
      end
    else
      def establish_connection(spec)
        pool = super(spec)
        FIXME
        tags_for_pool[pool] = (spec.config[:tags] || [])
        pool
      end
    end

    def all_tags(klass)
      tags = Cuddlefish.current_shard_tags
      tags = (tags | klass.shard_tags) if !Thread.current[Cuddlefish::CLASS_TAGS_DISABLED_KEY]
      tags
    end
  end
end
