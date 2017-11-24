require "spec_helper"

describe Cuddlefish::ShardManager do
  subject { described_class.new }
  let(:spec) do
    { tags: ["foo", "feline", "canine"],
      host: "localhost",
      port: 9506,
      username: "root",
      password: "swordfish",
      adapter: "mysql2",
      database: "foo_db",
    }
  end
  let(:other_spec) do
    { tags: ["bar", "feline", "canine"],
      host: "localhost",
      port: 9506,
      username: "root",
      password: "swordfish",
      adapter: "mysql2",
      database: "bar_db",
    }
  end

  describe "#add" do
    it "adds a new shard with a unique name" do
      expect { subject.add(spec) }.to change { subject.shards.count }.from(0).to(1)
      expect(subject.shards.last.name).to eq "localhost:foo_db:root:canine,feline,foo"
    end

    it "fails if you add two shards with the same name" do
      subject.add(spec)
      expect { subject.add(spec) }.to raise_error(Cuddlefish::InvalidShardSpecification, /Non-unique shard name/)
    end

    it "fails if you add a shard with no tags" do
      spec.delete(:tags)
      expect { subject.add(spec) }.to raise_error(Cuddlefish::InvalidShardSpecification, /No tags/)
    end
  end

  describe "#matching_connected_shards" do
    it "returns shards which have connection pools" do
      expect(subject.matching_connected_shards).to eq []
      shard = subject.add(spec)
      expect(subject.matching_connected_shards).to eq []
      subject.add_connection_pool(:fake_pool, shard)
      expect(subject.matching_connected_shards).to eq [shard]
      subject.remove_connection_pool(:fake_pool)
      expect(subject.matching_connected_shards).to eq []
    end

    it "filters based on the tags supplied" do
      shard = subject.add(spec)
      subject.add_connection_pool(:fake_pool, shard)
      expect(subject.matching_connected_shards([:foo, :feline])).to eq [shard]
      expect(subject.matching_connected_shards([:bar, :feline])).to eq []
    end
  end

  describe "#matching_shards" do
    it "returns all shards, regardless of whether they're connected" do
      expect(subject.matching_shards).to eq []
      shard = subject.add(spec)
      expect(subject.matching_shards).to eq [shard]
      subject.add_connection_pool(:fake_pool, shard)
      expect(subject.matching_shards).to eq [shard]
      subject.remove_connection_pool(:fake_pool)
      expect(subject.matching_shards).to eq [shard]
    end

    it "filters based on the tags supplied" do
      shard = subject.add(spec)
      expect(subject.matching_shards([:foo, :feline])).to eq [shard]
      expect(subject.matching_shards([:bar, :feline])).to eq []
    end
  end

  describe "#all_connection_pools" do
    it "returns the connection pools for all connected shards" do
      foo_shard = subject.add(spec)
      subject.add(other_spec)
      subject.add_connection_pool(:fake_pool, foo_shard)
      expect(subject.all_connection_pools).to eq [:fake_pool]
    end
  end

  describe "#find_by_name" do
    it "returns the shard with the given name" do
      shard = subject.add(spec)
      expect(subject.find_by_name(shard.name)).to eq shard
    end

    it "fails if you try to look up an unfamiliar name" do
      subject.add(spec)
      expect { subject.find_by_name("your mom") }.to raise_error(ArgumentError, /Couldn't find a shard/)
    end
  end
end
