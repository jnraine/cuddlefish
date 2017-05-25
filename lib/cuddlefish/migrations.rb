# Support for running ActiveRecord migrations on their appropriate shards.

module ActiveRecord
  class MigrationProxy
    def tag
      return @tag if @tag
      ActiveRecord::Migrator.migrations_paths.each do |path|
        path = path.chomp("/")
        if filename =~ %r<^#{path}/([^/]+)/>
          return (@tag = $1.to_sym)
        end
      end
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
        grouped_migrations = migrations(migrations_paths).select {|m| m.version == target_version }.group_by(&:tag)
        grouped_migrations.each do |tag, migrations_for_tag|
          Cuddlefish.with_exact_shard_tags(tag) { new(direction, migrations_for_tag, target_version).run }
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
        tags = migrations.map(&:tag).uniq

        Cuddlefish.each_tag(tags) { new(:up, migrations, target_version).migrate }
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
        tags = migrations.map(&:tag).uniq

        Cuddlefish.each_tag(tags) { new(:down, migrations, target_version).migrate }
      end
    end
  end
end
