module Cuddlefish
  class Shard
    include Cuddlefish::Helpers

    FAKE_ENVIRONMENT_NAME = :"your mom"

    attr_reader :tags, :connection_spec

    def initialize(config)
      @tags = config[:tags].map!(&:to_sym)
      @config = config
      @resolver = ::ActiveRecord::ConnectionAdapters::ConnectionSpecification::Resolver.new({FAKE_ENVIRONMENT_NAME => config})
      @connection_spec = make_connection_spec
    end

    %i(tags host database adapter port username password).each do |method|
      define_method(:method) { @config[method] }
    end

    private

    def make_connection_spec
      adapter_method = "#{@config[:adapter]}_connection"
      @resolver.spec(@config)
    end
  end
end
