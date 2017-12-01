# This sets up a Railtie which loads the file "config/cuddlefish.rb" when
# your Rails app starts up. You can put any necessary cuddlefish-related
# initialization in there.

require "active_model/railtie"

module Cuddlefish
  class Railtie < Rails::Railtie
    initializer "cuddlefish.initialize_database",
                before: "active_record.initialize_database" do |app|
      ActiveSupport.on_load(:active_record) do
        require Rails.root.join("config/cuddlefish.rb")
      end
    end
  end
end
