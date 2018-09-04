# frozen_string_literal: true

# Entry point for DatabaseConnection
module PgDice
  # Wrapper class around database connection handlers
  class DatabaseConnection
    attr_reader :pg_connection

    def initialize(configuration = Configuration.new)
      @configuration = configuration
      @pg_connection = configuration.pg_connection
    end

    def execute(query, params = [])
      @pg_connection ||= PG::Connection.new(@configuration.database_url)
      pg_connection.exec_params(query, params)
    end

    def exec(query)
      @pg_connection ||= PG::Connection.new(@configuration.database_url)
      pg_connection.exec(query)
    end
  end
end
