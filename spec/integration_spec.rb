require "spec_helper"

# For the integration tests, you need to provide a database for it to
# connect to. The user you're connecting with needs permissions to create
# databases and tables. You can customize the host, port, user, and
# password with the environment variables below.
#
# Before running these tests, run the "spec/db_setup.sql" file on your
# database server to create the necessary databases and tables.

describe "Basic Cuddlefish functionality" do
  before do
    Cuddlefish.current_shard_tags = []
  end

  describe ".use_shard_tags" do
    it "can talk to the database (sanity check)" do
      Cuddlefish.use_shard_tags(:foo) do
        expect(Cuddlefish::Cat.connection.execute("SELECT 33 FROM dual").to_a).to eq [[33]]
      end
    end

    it "uses the right connection for a given tag" do
      Cuddlefish.use_shard_tags(:foo) do
        expect {
          Cuddlefish::Cat.create!(name: "Reginald")
        }.to change { Cuddlefish::Cat.count }.by(1)
      end
      Cuddlefish.use_shard_tags(:bar) do
        expect(Cuddlefish::Cat.count).to eq 0
      end
    end

    it "raises an error if more than one connection matches" do
      Cuddlefish.use_shard_tags(:feline) do
        expect {
          Cuddlefish::Cat.create!(name: "Bloodthirster")
        }.to raise_error(Cuddlefish::TooManyMatchingConnections, /Found 2 connections/)
      end
    end

    it "raises an error if the model introduces a non-matching tag" do
      Cuddlefish.use_shard_tags(:cervine) do
        expect {
          Cuddlefish::Dog.create!(name: "Chryssalid")
        }.to raise_error(Cuddlefish::NoMatchingConnections)
      end
    end

    it "raises an error if no connections match" do
      Cuddlefish.use_shard_tags(:honk) do
        expect {
          Cuddlefish::Cat.create!(name: "Fiestaware")
        }.to raise_error(Cuddlefish::NoMatchingConnections)
      end
    end

    it "raises an error for unknown tags" do
      Cuddlefish.use_shard_tags(:not_a_tag) do
        expect {
          Cuddlefish::Cat.create!(name: "Pork Bun")
        }.to raise_error(Cuddlefish::NoMatchingConnections)
      end
    end

    it "restores previous shard tags when an exception happens" do
      begin
        Cuddlefish.use_shard_tags(:not_a_tag) do
          Cuddlefish::Cat.create!(name: "Snuggleguts")
        end
      rescue Cuddlefish::NoMatchingConnections
      end
      expect(Cuddlefish.current_shard_tags).to be_empty
    end

    it "uses the expected number of Mysql2::Client objects" do
      GC.start  # Clean up any Mysql2::Clients created by earlier tests
      Cuddlefish.use_shard_tags(:foo)  { Cuddlefish::Cat.create!(name: "Blastocyst") }
      Cuddlefish.use_shard_tags(:bar)  { Cuddlefish::Dog.create!(name: "Chiaroscuro") }
      Cuddlefish.use_shard_tags(:honk) { Cuddlefish::Gouda.create!(name: "Coatrack") }
      databases = []
      ObjectSpace.each_object do |obj|
        databases << obj.query_options[:database] if obj.is_a?(Mysql2::Client)
      end
      # nil element is from our `rebuild_schema` cleanup method
      expect(databases).to match_array ["foo_db", "bar_db", "honk_db", nil]
    end
  end

  describe ".replace_shard_tags" do
    it "ignores previously-specified tags from blocks" do
      Cuddlefish.use_shard_tags(:feline) do
        Cuddlefish.replace_shard_tags(:honk) do
          expect {
            Cuddlefish::Gouda.create(name: "Fondue")
          }.to change { Cuddlefish::Gouda.count }.by(1)
        end
      end
    end

    it "still honours tags on models" do
      Cuddlefish.replace_shard_tags(:honk) do
        expect {
          Cuddlefish::Cat.create(name: "Borgnine")
        }.to raise_error(Cuddlefish::NoMatchingConnections)
      end
    end

    it "raises an error for unknown tags" do
      Cuddlefish.replace_shard_tags(:not_a_tag) do
        expect {
          Cuddlefish::Cat.create!(name: "Partridge")
        }.to raise_error(Cuddlefish::NoMatchingConnections)
      end
    end

    it "restores previous shard tags when an exception happens" do
      begin
        Cuddlefish.replace_shard_tags(:not_a_tag) do
          Cuddlefish::Cat.create!(name: "Moulding")
        end
      rescue Cuddlefish::NoMatchingConnections
      end
      expect(Cuddlefish.current_shard_tags).to be_empty
    end
  end

  describe ".force_shard_tags" do
    it "ignores previously-specified tags from blocks" do
      Cuddlefish.use_shard_tags(:feline) do
        Cuddlefish.force_shard_tags(:honk) do
          expect {
            Cuddlefish::Gouda.create(name: "Raclette")
          }.to change { Cuddlefish::Gouda.count }.by(1)
        end
      end
    end

    it "ignores tags on models" do
      Cuddlefish.force_shard_tags(:honk) do
        expect {
          Cuddlefish::Cat.create(name: "Anastasia")
        }.to raise_error(ActiveRecord::StatementInvalid, /Table 'honk_db.cats' doesn't exist/)
      end
    end

    it "raises an error for unknown tags" do
      Cuddlefish.force_shard_tags(:not_a_tag) do
        expect {
          Cuddlefish::Cat.create!(name: "Greg")
        }.to raise_error(Cuddlefish::NoMatchingConnections)
      end
    end

    it "restores previous shard tags when an exception happens" do
      begin
        Cuddlefish.force_shard_tags(:not_a_tag) do
          Cuddlefish::Cat.create!(name: "Lucy")
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
      Cuddlefish.use_shard_tags(:foo) do
        expect(Cuddlefish::Cat.where(name: "Phlegm").count).to eq 1
        expect(Cuddlefish::Dog.count).to eq 0
      end
      Cuddlefish.use_shard_tags(:bar) do
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

  describe "force shard tags (non-block form)" do
    after { Cuddlefish.unforce_shard_tags! }

    it "requires specific shard tags for subsequent database calls" do
      Cuddlefish.force_shard_tags!(:honk)
      expect do
        Cuddlefish::Dog.first
      end.to raise_error(ActiveRecord::StatementInvalid, /Table 'honk_db.dogs' doesn't exist/)
      Cuddlefish.unforce_shard_tags!
    end

    it "correctly restores state with nested `force_shard_tags`" do
      expect do
        Cuddlefish.force_shard_tags(:honk) do
          Cuddlefish.force_shard_tags(:foo) do
            expect(Cuddlefish.class_tags_disabled?).to eq(true)
            expect(Cuddlefish.current_shard_tags).to eq([:foo])
          end

          expect(Cuddlefish.class_tags_disabled?).to eq(true)
          expect(Cuddlefish.current_shard_tags).to eq([:honk])
        end
      end.not_to change { [Cuddlefish.class_tags_disabled?, Cuddlefish.current_shard_tags] }
    end

    it "maintains state when called many times" do
      Cuddlefish.add_shard_tags(:bar)

      expect { Cuddlefish.unforce_shard_tags! }.not_to change { Cuddlefish.current_shard_tags }
    end
  end

  describe "connection handler" do
    it "starts with one pool for each shard" do
      expect(Cuddlefish::Cat.connection_handler.connection_pool_list.count).to eq 3
    end

    it "allows manually removing connections" do
      expect do
        Cuddlefish.use_shard_tags(:foo) do
          Cuddlefish::Cat.connection_handler.remove_connection(Cuddlefish::Cat)
        end
      end.to change { Cuddlefish::Cat.connection_handler.connection_pool_list.count }.from(3).to(2)
    end
  end

  describe "gem loading" do
    it "loads gem patches for gems in the Gemfile" do
      allow(Gem).to receive(:loaded_specs).and_return(double(key?: true))
      Cuddlefish.stop
      expect { setup }.to raise_error(LoadError, /cannot load such file -- activerecord-import\/base/)
    end
  end
end
