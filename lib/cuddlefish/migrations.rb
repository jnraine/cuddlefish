# Support for running ActiveRecord migrations on their appropriate shards.

module ActiveRecord
  class MigrationProxy
    def tags
      @tags = Cuddlefish.tags_for_migration.call(self).map(&:to_sym) if !defined?(@tag)
      @tags
    end
  end

  class Migration
    alias_method :original_announce, :announce

    def announce(message)
      host, db = connection.raw_connection.query_options.values_at(:host, :database)
      original_announce("[#{host}.#{db}] #{message}")
    end
  end

  class Migrator
    class << self

      # This is a monkey-patch. The previous version (in 4.2.8) was:
      #
      # def run(direction, migrations_paths, target_version)
      #   new(direction, migrations(migrations_paths), target_version).run
      # end

      def run(direction, migrations_paths, target_version)
        relevant_migrations = migrations(migrations_paths).select {|m| m.version == target_version }
        relevant_migrations.each do |migration|
          run_migration_on_shard(direction, migration, target_version)
        end
      end

      # This is a monkey-patch. The previous version (in 4.2.8) was:
      #
      # def up(migrations_paths, target_version = nil)
      #   migrations = migrations(migrations_paths)
      #   migrations.select! { |m| yield m } if block_given?
      #   new(:up, migrations, target_version).migrate
      # end

      def up(migrations_paths, target_version = nil)
        migrations = migrations(migrations_paths)
        migrations.select! { |m| yield m } if block_given?

        migrations.each do |migration|
          run_migration_on_shard(:up, migration, target_version)
        end
      end

      # This is a monkey-patch. The previous version (in 4.2.8) was:
      #
      # def down(migrations_paths, target_version = nil)
      #   migrations = migrations(migrations_paths)
      #   migrations.select! { |m| yield m } if block_given?
      #   new(:down, migrations, target_version).migrate
      # end

      def down(migrations_paths, target_version = nil)
        migrations = migrations(migrations_paths)
        migrations.select! { |m| yield m } if block_given?

        migrations.each do |migration|
          run_migration_on_shard(:down, migration, target_version)
        end
      end

      private

      def run_migration_on_shard(direction, migration, target_version)
        Cuddlefish.with_exact_shard_tags(*migration.tags) do
          new(direction, [migration], target_version).migrate
        end
      end
    end
  end
end
