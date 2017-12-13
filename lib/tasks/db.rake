# Move this into cuddlefish
namespace :cuddlefish do
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
