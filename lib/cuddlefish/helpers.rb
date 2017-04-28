# Utility methods for the other Cuddlefish classes.,

module Cuddlefish
  module Helpers
    def rails_4?
      ::ActiveRecord::VERSION::MAJOR == 4
    end

    def rails_5?
      ::ActiveRecord::VERSION::MAJOR == 5
    end
  end
end
