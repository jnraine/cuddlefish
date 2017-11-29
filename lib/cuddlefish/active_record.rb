# The monkey patches for ActiveRecord. Fortunately, they're not very extensive.

module Cuddlefish
  module ActiveRecord
    module Base
      include Cuddlefish::Helpers

      # If someone makes a database request with no tags, use these. (Shared
      # between all ActiveRecord::Base instances, since it's almost certainly
      # in a context where we don't know if the query is associated with a
      # particular model.)
      cattr_accessor(:default_shard_tags)
      self.default_shard_tags = []

      # The list of shard tags which should restrict this model's queries.
      def shard_tags
        @shard_tags ||= (self == ::ActiveRecord::Base ? ::ActiveRecord::Base.default_shard_tags : superclass.shard_tags)
      end

      # A class method to define this model's shard tags.
      def set_shard_tags(*tags)
        @shard_tags = tags.map(&:to_sym)
        self.connection_specification_name = self if !rails_4?
      end

      def establish_connection(_spec = nil)
        connection_handler = ::ActiveRecord::Base.default_connection_handler
        Cuddlefish.shards.each do |shard|
          connection_handler.disconnect_shard(shard)
          connection_handler.establish_connection(nil, shard.connection_spec)
        end
      end
    end
  end
end

ActiveRecord::Base.extend(Cuddlefish::ActiveRecord::Base)
