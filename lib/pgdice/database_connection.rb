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
      @pg_connection ||= PG::Connection.new(database_url)
      logger.debug { "DatabaseConnection to execute query: #{query}" }
      pg_connection.exec(query)
    end

    private

    def logger
      @configuration.logger
    end

    def database_url
      return @configuration.database_url if @configuration.database_url
      raise PgDice::InvalidConfigurationError, 'database_url must be present!'
    end
  end
end
