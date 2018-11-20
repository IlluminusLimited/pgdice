# frozen_string_literal: true

# Entry point for DatabaseConnection
module PgDice
  # Wrapper class around database connection handlers
  class DatabaseConnection
    attr_reader :logger, :query_executor, :dry_run

    def initialize(logger:, query_executor:, dry_run: false)
      @logger = logger
      @dry_run = dry_run
      @query_executor = query_executor
    end

    def execute(query)
      if dry_run
        logger.debug { "DatabaseConnection skipping query since dry_run is \"true.\" Query: #{query}" }
        return PgDice::PgResponse.new
      end

      logger.debug { "DatabaseConnection to execute query: #{query}" }
      query_executor.call(query)
    end
  end

  # Null-object pattern for PG::Result since that object isn't straightforward to initialize
  class PgResponse
    def values
      []
    end
  end
end
