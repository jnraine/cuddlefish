# Utility methods for the other Cuddlefish classes.

module Cuddlefish
  module Helpers
    # We try to have as little Rails version-specific code as possible, but it's
    # occasionally unavoidable when you're digging into ActiveRecord's guts.
    def rails_4?
      ::ActiveRecord::VERSION::MAJOR == 4
    end

    def rails_5?
      ::ActiveRecord::VERSION::MAJOR == 5
    end

    # The utility class for thread-safe hashes changed between Rails 4 and 5.
    def new_thread_safe_hash(capacity = 5)
      klass = rails_4? ? ThreadSafe::Cache : Concurrent::Map
      klass.new(initial_capacity: capacity)
    end
  end
end
