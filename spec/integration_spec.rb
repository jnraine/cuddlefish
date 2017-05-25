require "spec_helper"

# For the integration tests, you need to provide a database for it to
# connect to. The user you're connecting with needs permissions to create!
# databases and tables. You can customize the host, port, user, and
# password with the environment variables below.
#
# Before running these tests, run the "spec/db_setup.sql" file on your
# database server to create! the necessary databases and tables.

describe "Basic Cuddlefish functionality" do
  describe ".with_shard_tags" do
    it "can talk to the database (sanity check)" do
      Cuddlefish.with_shard_tags(:foo) do
        expect(Cuddlefish::Cat.connection.execute("SELECT 33 FROM dual").to_a).to eq [[33]]
      end
    end

    it "uses the right connection for a given tag" do
      Cuddlefish.with_shard_tags(:foo) do
        expect {
          Cuddlefish::Cat.create!(name: "Reginald")
        }.to change { Cuddlefish::Cat.count }.by(1)
      end
      Cuddlefish.with_shard_tags(:bar) do
        expect(Cuddlefish::Cat.count).to eq 0
      end
    end

    it "raises an error if more than one connection matches" do
      Cuddlefish.with_shard_tags(:feline) do
        expect {
          Cuddlefish::Cat.create!(name: "Bloodthirster")
        }.to raise_error(Cuddlefish::TooManyMatchingConnections, /Found 2 connections/)
      end
    end

    it "raises an error if the model introduces a non-matching tag" do
      Cuddlefish.with_shard_tags(:cervine) do
        expect {
          Cuddlefish::Dog.create!(name: "Chryssalid")
        }.to raise_error(Cuddlefish::NoMatchingConnections)
      end
    end

    it "raises an error if no connections match" do
      Cuddlefish.with_shard_tags(:honk) do
        expect {
          Cuddlefish::Cat.create!(name: "Fiestaware")
        }.to raise_error(Cuddlefish::NoMatchingConnections)
      end
    end

    it "raises an error for unknown tags" do
      Cuddlefish.with_shard_tags(:not_a_tag) do
        expect {
          Cuddlefish::Cat.create!(name: "Pork Bun")
        }.to raise_error(Cuddlefish::NoMatchingConnections)
      end
    end

    it "restores previous shard tags when an exception happens" do
      begin
        Cuddlefish.with_shard_tags(:not_a_tag) do
          Cuddlefish::Cat.create!(name: "Snuggleguts")
        end
      rescue Cuddlefish::NoMatchingConnections
      end
      expect(Cuddlefish.current_shard_tags).to be_empty
    end

    it "uses the expected number of Mysql2::Client objects" do
      Cuddlefish.with_shard_tags(:foo)  { Cuddlefish::Cat.create!(name: "Blastocyst") }
      Cuddlefish.with_shard_tags(:bar)  { Cuddlefish::Dog.create!(name: "Chiaroscuro") }
      Cuddlefish.with_shard_tags(:honk) { Cuddlefish::Gouda.create!(name: "Coatrack") }
      databases = []
      ObjectSpace.each_object do |obj|
        databases << obj.query_options[:database] if obj.is_a?(Mysql2::Client)
      end
      expect(databases).to match_array ["foo_db", "bar_db", "honk_db"]
    end
  end

  describe ".with_exact_shard_tags" do
    it "ignores previously-specified tags from blocks" do
      Cuddlefish.with_shard_tags(:feline) do
        Cuddlefish.with_exact_shard_tags(:honk) do
          expect {
            Cuddlefish::Gouda.create(name: "Fondue")
          }.to change { Cuddlefish::Gouda.count }.by(1)
        end
      end
    end

    it "still honours tags on models" do
      Cuddlefish.with_exact_shard_tags(:honk) do
        expect {
          Cuddlefish::Cat.create(name: "Borgnine")
        }.to raise_error(Cuddlefish::NoMatchingConnections)
      end
    end

    it "raises an error for unknown tags" do
      Cuddlefish.with_shard_tags(:not_a_tag) do
        expect {
          Cuddlefish::Cat.create!(name: "Partridge")
        }.to raise_error(Cuddlefish::NoMatchingConnections)
      end
    end

    it "restores previous shard tags when an exception happens" do
      begin
        Cuddlefish.with_exact_shard_tags(:not_a_tag) do
          Cuddlefish::Cat.create!(name: "Moulding")
        end
      rescue Cuddlefish::NoMatchingConnections
      end
      expect(Cuddlefish.current_shard_tags).to be_empty
    end
  end

  describe ".add_shard_tags & .remove_shard_tags" do
    it "change the current shard tags" do
      expect {
        Cuddlefish.add_shard_tags(:feline, :foo)
      }.to change { Cuddlefish.current_shard_tags }.from([]).to([:feline, :foo])
      Cuddlefish::Cat.create!(name: "Curry Nog")
      expect {
        Cuddlefish.remove_shard_tags(:feline)
      }.to change { Cuddlefish.current_shard_tags }.from([:feline, :foo]).to([:foo])
      expect {
        Cuddlefish.remove_shard_tags(:foo)
      }.to change { Cuddlefish.current_shard_tags }.from([:foo]).to([])
    end
  end

  describe ".each_tag" do
    it "runs the block in the context of each tag" do
      Cuddlefish.each_tag(:foo, :bar) do
        Cuddlefish::Cat.create!(name: "Phlegm")
      end
      Cuddlefish.with_shard_tags(:foo) do
        expect(Cuddlefish::Cat.where(name: "Phlegm").count).to eq 1
        expect(Cuddlefish::Dog.count).to eq 0
      end
      Cuddlefish.with_shard_tags(:bar) do
        expect(Cuddlefish::Cat.where(name: "Phlegm").count).to eq 1
        expect(Cuddlefish::Dog.count).to eq 0
      end
    end
  end

  describe ".each_shard" do
    it "runs the block once for every shard" do
      databases = []
      Cuddlefish.each_shard do
        databases << ActiveRecord::Base.connection.raw_connection.query_options[:database]
      end
      expect(databases).to match_array ["foo_db", "bar_db", "honk_db"]
    end
  end

  describe ".map_shards" do
    it "runs the block once for every shard and returns the results" do
      databases = Cuddlefish.map_shards do
        ActiveRecord::Base.connection.raw_connection.query_options[:database]
      end
      expect(databases).to match_array ["foo_db", "bar_db", "honk_db"]
    end
  end
end
