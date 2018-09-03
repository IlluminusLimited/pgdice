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
    # private

    # def build_postgres_url
    #   # config = Rails.configuration.database_configuration
    #   # host = config[Rails.env]['host']
    #   # database = config[Rails.env]['database']
    #   # username = config[Rails.env]['username']
    #   # password = config[Rails.env]['password']
    #   username = 'bob'
    #   password = 'bob'
    #   host = 'bob'
    #   database = 'bob'
    #   "postgres://#{username}:#{password}@#{host}/#{database}"
    # end
  end
end
