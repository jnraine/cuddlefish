require "spec_helper"
require "fileutils"

describe "Cuddlefish migration support" do
  def with_new_schema(&block)
    rebuild_schema
    block.call
    rebuild_schema
  end

  around do |example|
    with_new_schema { example.run }
  end

  let(:base_dir) { "/tmp/cuddlefish-db/migrate" }

  before do
    FileUtils.rm_rf(base_dir)

    FileUtils.mkdir_p("#{base_dir}/foo")
    File.open("#{base_dir}/foo/20010101010000_do_some_stuff.rb", "w") do |f|
      f.puts <<~MIGRATION
        class DoSomeStuff < ActiveRecord::Migration
          self.shard_tags = [:foo]

          def change
            add_column :cats, :lives_remaining, :integer, default: 69105
          end
        end
      MIGRATION
    end

    FileUtils.mkdir_p("#{base_dir}/bar")
    File.open("#{base_dir}/bar/20170102030405_do_other_stuff.rb", "w") do |f|
      f.puts <<~MIGRATION
        class DoOtherStuff < ActiveRecord::Migration
          self.shard_tags = [:bar]

          def change
            add_column :dogs, :flea_count, :integer, default: 31337
          end
        end
      MIGRATION
    end

    ActiveRecord::Migrator.migrations_paths = [base_dir]
  end

  describe "#up/#down" do
    it "run the migrations on the correct shards" do
      Cuddlefish.use_shard_tags(:foo) do
        Cuddlefish::Cat.create!(name: "Spaetzle")
        ActiveRecord::Migrator.up(ActiveRecord::Migrator.migrations_paths)
      end

      Cuddlefish.use_shard_tags(:bar) do
        Cuddlefish::Dog.create!(name: "Knockwurst")
        ActiveRecord::Migrator.up(ActiveRecord::Migrator.migrations_paths)
      end

      Cuddlefish.use_shard_tags(:foo) do
        expect(Cuddlefish::Cat.first.lives_remaining).to eq 69105
        expect {
          Cuddlefish::Dog.first.flea_count
        }.to raise_error(NoMethodError, /undefined method `flea_count'/)
      end

      Cuddlefish.use_shard_tags(:bar) do
        expect(Cuddlefish::Dog.first.flea_count).to eq 31337
        expect {
          Cuddlefish::Cat.first.lives_remaining
        }.to raise_error(NoMethodError, /undefined method `lives_remaining'/)
      end
    end
  end

  describe "#run" do
    it "runs the migrations on the correct shards" do
      Cuddlefish.use_shard_tags(:foo) do
        Cuddlefish::Cat.create!(name: "Paolo")

        ActiveRecord::Migrator.run(:up, ActiveRecord::Migrator.migrations_paths, 20010101010000)

        expect(Cuddlefish::Cat.first.lives_remaining).to eq 69105

        ActiveRecord::Migrator.run(:down, ActiveRecord::Migrator.migrations_paths, 20010101010000)
      end

      Cuddlefish.use_shard_tags(:bar) do
        Cuddlefish::Dog.create!(name: "Francesca")
        ActiveRecord::Migrator.run(:up, ActiveRecord::Migrator.migrations_paths, 20170102030405)
      end

      Cuddlefish.use_shard_tags(:bar) do
        expect(Cuddlefish::Dog.first.flea_count).to eq 31337
      end
    end
  end
end
