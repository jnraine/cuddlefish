module Cuddlefish
  class DatabaseTasks
    def self.create(shard_config_path)
      environments.each do |env|
        load_config(shard_config_path).fetch(env).each do |shard_config|
          ::ActiveRecord::Tasks::DatabaseTasks.create(shard_config)
        end
      end
    end

    def self.create_all(shard_config_path)
      cuddlefish_config.each do |_env, shard_config_list|
        load_config(shard_config_path).each do |shard_config|
          ::ActiveRecord::Tasks::DatabaseTasks.create(shard_config)
        end
      end
    end

    def self.drop(shard_config_path)
      environments.each do |env|
        load_config(shard_config_path).fetch(env).each do |shard_config|
          ::ActiveRecord::Tasks::DatabaseTasks.drop(shard_config)
        end
      end
    end

    def self.drop_all(shard_config_path)
      load_config(shard_config_path).each do |_env, shard_config_list|
        shard_config_list.each do |shard_config|
          ::ActiveRecord::Tasks::DatabaseTasks.drop(shard_config)
        end
      end
    end

    # Simulate the behaviour from https://github.com/rails/rails/blob/67fefbe0c2de5d55b4d30958ce70d659c1c4cf35/activerecord/lib/active_record/tasks/database_tasks.rb#L309-L311
    private_class_method def self.environments
      environments = [Rails.env.to_s]
      environments << "test" if environments == ["development"]
      environments
    end

    private_class_method def self.load_config(path)
      YAML.load(File.read(path))
    end
  end
end
