# frozen_string_literal: true

# Entry point for DatabaseConnection
module PgDice
  # Wrapper class around database connection handlers
  class DatabaseConnection
    extend Forwardable
    def_delegators :@configuration, :logger, :dry_run, :pg_connection

    def initialize(configuration = PgDice::Configuration.new)
      @configuration = configuration
    end

    def execute(query)
      logger.debug { "DatabaseConnection to execute query: #{query}" }
      if dry_run
        PgDicePgResponse.new
      else
        pg_connection.exec(query)
      end
    end
  end

  # Null-object pattern for PG::Result since that object isn't straightforward to initialize
  class PgDicePgResponse
    def values
      []
    end
  end
end
