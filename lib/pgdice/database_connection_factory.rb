# frozen_string_literal: true

# Entry point
module PgDice
  #  DatabaseConnectionFactory is a class used to build DatabaseConnections
  class DatabaseConnectionFactory
    extend Forwardable

    def_delegators :@configuration, :logger, :dry_run

    def initialize(configuration, opts = {})
      @configuration = configuration
      @query_executor_factory = opts[:query_executor_factory] ||= PgDice::QueryExecutorFactory.new(configuration, opts)
    end

    def call
      PgDice::DatabaseConnection.new(logger: logger, query_executor: @query_executor_factory.call, dry_run: dry_run)
    end
  end
end
