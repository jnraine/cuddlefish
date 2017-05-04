require "spec_helper"
require "fileutils"

describe "Cuddlefish migration support" do
  let(:base_dir) { "/tmp/db/migrate" }

  before do
    FileUtils.rm_rf(base_dir)

    FileUtils.mkdir_p("#{base_dir}/foo")
    File.open("#{base_dir}/foo/20170101020304_do_some_stuff.rb", "w") do |f|
      f.puts <<MIGRATION
class DoSomeStuff < ActiveRecord::Migration
  def change
    add_column :cats, :lives_remaining, :integer, default: 69105
  end
end
MIGRATION
    end

    FileUtils.mkdir_p("#{base_dir}/bar")
    File.open("#{base_dir}/bar/20170102030405_do_other_stuff.rb", "w") do |f|
      f.puts <<MIGRATION
class DoOtherStuff < ActiveRecord::Migration
  def change
    add_column :dogs, :flea_count, :integer, default: 31337
  end
end
MIGRATION
    end

    ActiveRecord::Migrator.migrations_paths = [base_dir]
  end

  after do
    ActiveRecord::Migrator.down(ActiveRecord::Migrator.migrations_paths)
  end

  it "runs the migrations on the correct shards" do
    Cuddlefish.with_shard_tags(:foo) do
      Cuddlefish::Cat.create!(name: "Spaetzle")
    end
    Cuddlefish.with_shard_tags(:bar) do
      Cuddlefish::Dog.create!(name: "Knockwurst")
    end

    ActiveRecord::Migrator.up(ActiveRecord::Migrator.migrations_paths)

    Cuddlefish.with_shard_tags(:foo) do
      expect(Cuddlefish::Cat.first.lives_remaining).to eq 69105
      expect {
        Cuddlefish::Dog.first.flea_count
      }.to raise_error(NoMethodError, /undefined method `flea_count'/)
    end

    Cuddlefish.with_shard_tags(:bar) do
      expect(Cuddlefish::Dog.first.flea_count).to eq 31337
      expect {
        Cuddlefish::Cat.first.lives_remaining
      }.to raise_error(NoMethodError, /undefined method `lives_remaining'/)
    end
  end
end
