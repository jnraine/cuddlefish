# Move this into cuddlefish
namespace :cuddlefish do
  task force_shard_tags: :environment do
    if ENV.key?("SHARD_TAGS")
      shard_tags = ENV.fetch("SHARD_TAGS").split(",").map(&:to_sym)
      Cuddlefish.force_shard_tags!(shard_tags)
    else
      $remaining_shards = Cuddlefish.shards.dup
      next_shard = $remaining_shards.shift
      puts "Running against #{next_shard.name.inspect} shard"
      Cuddlefish.force_shard_tags!(next_shard.tags)
    end
  end

  task :force_next_shard do
    next_shard = $remaining_shards.shift

    if next_shard
      puts "Running against #{next_shard.name.inspect} shard"
      Cuddlefish.force_shard_tags!(next_shard.tags)
      # Re-enable db:structure:dump so it'll run again when we execute db:migrate again
      Rake::Task["db:structure:dump"].reenable
      Rake::Task["db:migrate"].execute
      Rake::Task["cuddlefish:force_next_shard"].execute
    end
  end

  task require_unique_shard: :environment do
    if ENV.key?("SHARD_TAGS")
      tags = ENV.fetch("SHARD_TAGS").split(",").map(&:to_sym)
      matching_shards = Cuddlefish.shards.select do |shard|
        tags.all? {|tag| shard.tags.include?(tag) }
      end

      case matching_shards.length
      when 0 then raise "No matching shard found for shard tags: #{shard_tags.inspect}"
      when 1 then Cuddlefish.force_shard_tags!(tags)
      else
        raise "More than one shard found for shard tags (must match only one): #{tags.inspect}"
      end
    else
      raise <<~MESSAGE
        You must specify a shard to run this task on by setting SHARD_TAGS.
        Check config/shards.yml for information on each shard.

        For example:

        rake db:migrate:down VERSION=20171219064114 SHARD_TAGS=iris
        rake db:migrate:up VERSION=20171219064114 SHARD_TAGS=themis
        rake db:migrate:redo SHARD_TAGS=common,shard_0
      MESSAGE
    end
  end

  namespace :db do
    desc "Create databases for every configured shard"
    task :create do
      Cuddlefish::DatabaseTasks.create(Rails.root.join("config/shards.yml").to_s)
    end

    namespace :create do
      desc "Create databases for every configured shard in all environments"
      task :all do
        Cuddlefish::DatabaseTasks.create_all(Rails.root.join("config/shards.yml").to_s)
      end
    end

    desc "Drop databases for every configured shard"
    task :drop do
      Cuddlefish::DatabaseTasks.drop(Rails.root.join("config/shards.yml").to_s)
    end

    desc "Drop databases for every configured shard in all environments"
    namespace :drop do
      task :all do
        Cuddlefish::DatabaseTasks.drop_all(Rails.root.join("config/shards.yml").to_s)
      end
    end
  end
end
