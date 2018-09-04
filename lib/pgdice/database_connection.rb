# frozen_string_literal: true

# Entry point for DatabaseConnection
module PgDice
  # Wrapper class around database connection handlers
  class DatabaseConnection
    attr_reader :pg_connection

    def initialize(configuration = PgDice::Configuration.new)
      @configuration = configuration
      @pg_connection = configuration.pg_connection
    end

    def execute(query)
      @pg_connection ||= PG::Connection.new(@configuration.database_url)
      logger.debug { "DatabaseConnection to execute query: #{query}" }
      pg_connection.exec(query)
    end

    private

    def logger
      @configuration.logger
    end
  end
end
