# frozen_string_literal: true

# Entry point for PartitionManager
module PgDice
  #  PartitionListerFactory is a class used to build PartitionListers
  class PartitionDropperFactory
    extend Forwardable

    def_delegators :@configuration, :logger, :database_connection

    def initialize(configuration, opts = {})
      @configuration = configuration
      @query_executor = opts[:query_executor] ||= ->(sql) { database_connection.execute(sql) }
    end

    def call
      PgDice::PartitionDropper.new(logger: logger, query_executor: @query_executor)
    end
  end
end
