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
      Rake::Task["db:create:all"].enhance { Rake::Task["cuddlefish:db:create:all"].invoke }
      Rake::Task["db:drop:all"].enhance { Rake::Task["cuddlefish:db:drop:all"].invoke }

      Rake::Task["db:migrate"].enhance(["cuddlefish:force_shard_tags"]) { Rake::Task["cuddlefish:force_next_shard"].invoke }

      # Eventually, upgrade the built-in rake tasks as follows:
      # rake db:migrate:up - Find migration, run against every shard that matches
      # rake db:migrate:down - Find migration, run against every shard that matches
      # rake db:rollback - Find latest migration, run against every shard that matches
      # rake db:redo - Find latest migration, run down/up against every shard that matches
      #
      # Until then, these will error out when they're run without SHARD_TAGS
      Rake::Task["db:migrate:up"].enhance(["cuddlefish:require_unique_shard"])
      Rake::Task["db:migrate:down"].enhance(["cuddlefish:require_unique_shard"])
      Rake::Task["db:migrate:redo"].enhance(["cuddlefish:require_unique_shard"])
      Rake::Task["db:rollback"].enhance(["cuddlefish:require_unique_shard"])

      # TODO: This task doesn't use our monkey patch to filter out migrations belonging to other shards.
      Rake::Task["db:migrate:status"].enhance(["cuddlefish:require_unique_shard"])
    end
  end
end
