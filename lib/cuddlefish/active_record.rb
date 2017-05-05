# The monkey patches for ActiveRecord::Base. Fortunately, they're not very extensive.

module Cuddlefish
  module ActiveRecord
    include Cuddlefish::Helpers

    def shard_tags
      @shard_tags ||= []
    end

    def set_shard_tags(*tags)
      @shard_tags = tags.map(&:to_sym)
      self.connection_specification_name = self if !rails_4?
    end
  end
end

ActiveRecord::Base.extend(Cuddlefish::ActiveRecord)
