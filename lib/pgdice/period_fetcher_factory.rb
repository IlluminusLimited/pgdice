# frozen_string_literal: true

module PgDice
  # Factory for PeriodFetcher
  class PeriodFetcherFactory
    extend Forwardable

    def_delegators :@configuration, :database_connection

    def initialize(configuration, opts = {})
      @configuration = configuration
      @query_executor = opts[:query_executor] ||= ->(sql) { database_connection.execute(sql).values.flatten.compact }
    end

    def call
      PgDice::PeriodFetcher.new(query_executor: @query_executor)
    end
  end
end
