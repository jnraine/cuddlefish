# A class which keeps track of all the user-defined shards.

module Cuddlefish
  class InvalidShardSpecification < StandardError; end

  class ShardManager
    attr_reader :shards

    def initialize
      @shards = []
    end

    def add(spec)
      spec = spec.symbolize_keys
      validate_tags_present(spec)
      if spec[:name].nil? || spec[:name].empty?
        tags = spec[:tags].sort.join(",")
        spec[:name] = [*spec.values_at(:host, :database, :username), tags].join(":").freeze
      end
      validate_unique_name(spec[:name])
      @shards << Cuddlefish::Shard.new(spec)
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
