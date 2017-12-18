# Move this into cuddlefish
namespace :cuddlefish do
  task force_shard_tags: :environment do
    if ENV.key?("SHARD_TAGS")
      shard_tags = ENV.fetch("SHARD_TAGS").split(",").map(&:to_sym)
      Cuddlefish.force_shard_tags!(shard_tags)
    else
      $shard_tag_list = Cuddlefish.shards.map(&:tags)
      next_shard_tags = $shard_tag_list.shift
      puts "Running db:migrate for #{next_shard_tags}"
      Cuddlefish.force_shard_tags!(next_shard_tags)
    end
  end

  task :force_next_shard do
    next_shard_tags = $shard_tag_list.shift

    if next_shard_tags
      puts "Running db:migrate for #{next_shard_tags}"
      Cuddlefish.force_shard_tags!(next_shard_tags)
      Rake::Task["db:migrate"].execute
      Rake::Task["cuddlefish:force_next_shard"].execute
    end
  end

  namespace :db do
    desc "Create databases for every configured shard"
    task :create do
      cuddlefish_config = YAML.load(Rails.root.join("config/shards.yml").read)
      cuddlefish_config.each do |_env, shard_config|
        shard_config.each do |shard_config|
          ActiveRecord::Tasks::DatabaseTasks.create(shard_config)
        end
      end
    end

    desc "Drop databases for every configured shard"
    task :drop do
      cuddlefish_config = YAML.load(Rails.root.join("config/shards.yml").read)
      cuddlefish_config.each do |_env, shard_config|
        shard_config.each do |shard_config|
          ActiveRecord::Tasks::DatabaseTasks.drop(shard_config)
        end
      end
    end
  end
end
