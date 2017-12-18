# This sets up a Railtie which loads the file "config/cuddlefish.rb" when
# your Rails app starts up. You can put any necessary cuddlefish-related
# initialization in there.

require "active_model/railtie"

module Cuddlefish
  class Railtie < Rails::Railtie
    initializer "cuddlefish.initialize_database", before: "active_record.initialize_database" do |app|
      ActiveSupport.on_load(:active_record) do
        require Rails.root.join("config/cuddlefish.rb")
      end
    end

    rake_tasks do
      load "#{File.dirname(__FILE__)}/../tasks/db.rake"

      Rake::Task["db:create"].enhance { Rake::Task["cuddlefish:db:create"].invoke }
      Rake::Task["db:drop"].enhance { Rake::Task["cuddlefish:db:drop"].invoke }

      Rake::Task["db:migrate"].enhance(["cuddlefish:force_shard_tags"]) { Rake::Task["cuddlefish:force_next_shard"].invoke }
      Rake::Task["db:migrate:up"].enhance(["cuddlefish:force_shard_tags"])
      Rake::Task["db:migrate:down"].enhance(["cuddlefish:force_shard_tags"])
      Rake::Task["db:migrate:redo"].enhance(["cuddlefish:force_shard_tags"])
      Rake::Task["db:rollback"].enhance(["cuddlefish:force_shard_tags"])
      Rake::Task["db:migrate:status"].enhance(["cuddlefish:force_shard_tags"])
    end
  end
end
