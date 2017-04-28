module Cuddlefish
  class TooManyMatchingConnections < Error; end
  class NoMatchingConnections < Error; end

  class ConnectionHandler < ::ActiveRecord::ConnectionAdapters::ConnectionHandler
    extend Helpers

    # FIXME: This is a terrible implementation of looking up pools by tags.
    # It's slow as BALLS. Fix it up later, once you've proved that the
    # proof of concept works.

    def initialize
      @tags_for_pool = {}
      super
      Cuddlefish.shards.each do |shard|
        pool = establish_connection(OpenStruct.new(name: "FIXME herp a derp"), shard.connection_spec, tags: shard.tags)
      end
    end

    # FIXME: SOOOOOOO SLOOOOOOOOW.
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
      binding.pry if Cuddlefish.current_shard_tags.nil?
      binding.pry if klass.shard_tags.nil?
      Cuddlefish.current_shard_tags + klass.shard_tags
    end
  end
end
