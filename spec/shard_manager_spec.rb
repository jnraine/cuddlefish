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

  describe ".add" do
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
end
