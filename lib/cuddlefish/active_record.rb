# The monkey patches for ActiveRecord. This should be extended into
# ActiveRecord::Base itself if you want to use Cuddlefish on all your
# models, or extended separately into each individual model otherwise.

module Cuddlefish
  module ActiveRecord
    def self.included(klass)
      class << klass
        def shard_tags
          @shard_tags || []
        end

        def set_shard_tags(*tags)
          @shard_tags = tags.map(&:to_sym)
        end
      end
    end

    # FIXME: document the hell out of this
    def connection_specification_name
      self
    end
  end
end
