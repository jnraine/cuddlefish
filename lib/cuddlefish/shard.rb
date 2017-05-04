# A simple data structure for storing the tags and the Rails
# ConnectionSpecification associated with a given shard.

module Cuddlefish
  class Shard
    # The actual value doesn't matter. Resolver just expects its arguments in the form "{environment name => config}",
    # so we give it some random environment name to keep it happy.
    FAKE_ENVIRONMENT_NAME = :"your mom's favourite environment"

    attr_reader :tags, :connection_spec

    def initialize(config)
      @tags = config[:tags].map!(&:to_sym)
      @config = config
      @connection_spec = make_connection_spec
    end

    %i(tags host database adapter port username password).each do |method|
      define_method(:method) { @config[method] }
    end

    def matches?(desired_tags)
      (desired_tags - @tags).empty?
    end

    private

    def make_connection_spec
      resolver = ::ActiveRecord::ConnectionAdapters::ConnectionSpecification::Resolver.new({FAKE_ENVIRONMENT_NAME => @config})
      resolver.spec(@config)
    end
  end
end
