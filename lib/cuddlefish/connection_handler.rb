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
      @tags_for_pool = {}
      super
      Cuddlefish.shards.each do |shard|
        if self.class.rails_4?
          establish_connection(::ActiveRecord::Base, shard.connection_spec, tags: shard.tags)
        else
          establish_connection(shard.connection_spec, tags: shard.tags)
        end
      end
    end

    def retrieve_all_connection_pools(klass)
      desired_tags = all_tags(klass)
      @tags_for_pool.keys.select { |pool| (desired_tags - @tags_for_pool[pool]).empty? }
    end

    def retrieve_connection_pool(klass)
      pools = retrieve_all_connection_pools(klass)
      case pools.count
      when 0
        raise NoMatchingConnections.new("Found no connections matching #{all_tags(klass).inspect}")
      when 1
        pools.first
      else
        raise TooManyMatchingConnections.new("Found #{pools.count} connections matching #{all_tags(klass).inspect}")
      end
    end

    # The arguments to this method changed between Rails 4.2 and 5.0.
    if rails_4?
      def establish_connection(owner, spec, tags: nil)
        pool = super(owner, spec)
        @tags_for_pool[pool] = tags if tags
        pool
      end
    else
      def establish_connection(spec, tags: nil)
        pool = super(spec)
        @tags_for_pool[pool] = tags if tags
        pool
      end
    end

    private

    def all_tags(klass)
      tags = Cuddlefish.current_shard_tags
      tags += klass.shard_tags if klass.is_a?(Class)
      tags
    end
  end
end
