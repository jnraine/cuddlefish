# The monkey patches for ActiveRecord::Base.

module Cuddlefish
  module ActiveRecord
    def self.included(klass)
      class << klass
        def shard_tags
          @shard_tags || []
        end

        def set_shard_tags(*tags)
          @shard_tags = tags.map(&:to_sym)
          self.connection_specification_name = self
        end
      end
    end
  end
end
