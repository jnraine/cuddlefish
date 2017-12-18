# Support for running ActiveRecord migrations on their appropriate shards.
module Cuddlefish
  module ActiveRecord
    module MigrationClassMethods
      attr_accessor :shard_tags
    end

    module Migration
      def shard_tags
        self.class.shard_tags || raise("Shard tags not set. Add `self.shard_tags=` to the #{self.class.name} migration (version #{version}).")
      end

      def announce(message)
        host, db = connection.raw_connection.query_options.values_at(:host, :database)
        super("[#{host}.#{db}] #{message}")
      end
    end

    module MigratorClassMethods
      # Only return migrations when shard tags are currently enabled
      def migrations(*)
        super.select do |migration_proxy|
          migration_shard_tags = migration_proxy.send(:migration).shard_tags
          migration_shard_tags.all? do |migration_shard_tag|
            Cuddlefish.current_shard_tags.include?(migration_shard_tag)
          end
        end
      end
    end
  end
end

ActiveRecord::Migration.prepend(Cuddlefish::ActiveRecord::Migration)
ActiveRecord::Migration.singleton_class.include(Cuddlefish::ActiveRecord::MigrationClassMethods)
ActiveRecord::Migrator.singleton_class.prepend(Cuddlefish::ActiveRecord::MigratorClassMethods)
