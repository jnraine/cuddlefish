module Cuddlefish
  class DatabaseTasks
    def self.create(shards_config_path)
      cuddlefish_config = YAML.load(File.read(shards_config_path))

      environments.each do |env|
        cuddlefish_config.fetch(env).each do |shard_config|
          ::ActiveRecord::Tasks::DatabaseTasks.create(shard_config)
        end
      end
    end

    def self.create_all(shards_config_path)
      cuddlefish_config = YAML.load(File.read(shards_config_path))

      cuddlefish_config.each do |_env, shard_config_list|
        shard_config_list.each do |shard_config|
          ::ActiveRecord::Tasks::DatabaseTasks.create(shard_config)
        end
      end
    end

    def self.drop(shards_config_path)
      cuddlefish_config = YAML.load(File.read(shards_config_path))

      environments.each do |env|
        cuddlefish_config.fetch(env).each do |shard_config|
          ::ActiveRecord::Tasks::DatabaseTasks.drop(shard_config)
        end
      end
    end

    def self.drop_all(shards_config_path)
      cuddlefish_config = YAML.load(File.read(shards_config_path))

      cuddlefish_config.each do |_env, shard_config_list|
        shard_config_list.each do |shard_config|
          ::ActiveRecord::Tasks::DatabaseTasks.drop(shard_config)
        end
      end
    end

    def self.env
      @env ||= Rails.env.to_s
    end

    # Simulate the behaviour from https://github.com/rails/rails/blob/67fefbe0c2de5d55b4d30958ce70d659c1c4cf35/activerecord/lib/active_record/tasks/database_tasks.rb#L309-L311
    private_class_method def self.environments
      environments = [env]
      environments << "test" if environments == ["development"]
      environments
    end
  end
end
