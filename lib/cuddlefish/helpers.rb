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
  end
end
