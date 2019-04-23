# frozen_string_literal: true

# Entry point for PartitionManager
module PgDice
  #  PartitionListerFactory is a class used to build PartitionListers
  class DatabaseConnectionFactory
    extend Forwardable

    def_delegators :@configuration, :logger, :pg_connection, :dry_run

    def initialize(configuration, opts = {})
      @configuration = configuration
      @query_executor = opts[:query_executor] ||= PgDice::QueryExecutor.new(logger: logger,
                                                                            connection_supplier: -> { pg_connection })
    end

    def call
      PgDice::DatabaseConnection.new(logger: logger, query_executor: @query_executor, dry_run: dry_run)
    end
  end
end
