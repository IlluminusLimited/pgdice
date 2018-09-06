# frozen_string_literal: true

# Entry point for DatabaseConnection
module PgDice
  # Wrapper class around database connection handlers
  class DatabaseConnection
    extend Forwardable
    def_delegators :@configuration, :logger

    def initialize(configuration = PgDice::Configuration.new)
      @configuration = configuration
    end

    def execute(query)
      @configuration.pg_connection ||= PG::Connection.new(@configuration.database_url)
      logger.debug { "DatabaseConnection to execute query: #{query}" }
      @configuration.pg_connection.exec(query)
    end
  end
end
