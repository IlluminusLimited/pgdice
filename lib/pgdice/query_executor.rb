# frozen_string_literal: true

# Entry point for DatabaseConnection
module PgDice
  # Wrapper class around pg_connection to reset connection on PG errors
  class QueryExecutor
    attr_reader :logger

    def initialize(logger:, connection_supplier:)
      @logger = logger
      @connection_supplier = connection_supplier
    end

    def call(query)
      @connection_supplier.call.exec(query)
    rescue PG::Error => error
      logger.error { "Caught error: #{error}. Going to reset connection and try again" }
      @connection_supplier.call.reset
      @connection_supplier.call.exec(query)
    end
  end
end
