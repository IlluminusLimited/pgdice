# frozen_string_literal: true

# Entry point
module PgDice
  #  QueryExecutorFactory is a class used to build QueryExecutors
  class QueryExecutorFactory
    extend Forwardable

    def_delegators :@configuration, :logger, :pg_connection

    def initialize(configuration, opts = {})
      @configuration = configuration
      @connection_supplier = opts[:connection_supplier] ||= -> { pg_connection }
    end

    def call
      PgDice::QueryExecutor.new(logger: logger, connection_supplier: @connection_supplier)
    end
  end
end
