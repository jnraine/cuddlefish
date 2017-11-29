# activerecord-import is a gem which allows you to create bulk INSERT statements for
# ActiveRecord models. We have to do some workarounds to keep it functioning properly
# because we're both trying to monkey-patch the same code.

module ActiveRecord
  class Base
    # We have to redefine establish_connection directly in this manner because otherwise
    # AR::Import will get in our way by aliasing methods on ActiveRecord::Base.

    def self.establish_connection(spec = nil)
      method = ::Cuddlefish::ActiveRecord::Base.instance_method(:establish_connection)
      method.bind(self).call(spec)
    end
  end
end

# Because cuddlefish monkey-patches some ActiveRecord behaviour which activerecord-import
# relies upon to work correctly, we have to set it up manually afterwards.
if !ActiveRecord.const_defined?(:Import)
  require "activerecord-import/base"
  Cuddlefish.shards.map(&:adapter).uniq.each do |adapter|
    ActiveRecord::Import.require_adapter(adapter)
  end
end
