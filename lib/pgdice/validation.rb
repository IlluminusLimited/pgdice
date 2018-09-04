# frozen_string_literal: true

module PgDice
  # Collection of utilities that provide ways for users to ensure things are working properly
  class Validation
    def initialize(configuration = PgDice::Configuration.new)
      @configuration = configuration
    end

    def assert_future_tables(table_name, future_tables, interval = 'days')
      sql = build_assert_sql(table_name, future_tables, interval)

      response = database_connection.execute(sql)

      return if response.values.size == 1
      raise PgDice::InsufficientFutureTablesError, "Insufficient future tables exist for table: #{table_name}. "\
"Expected: #{future_tables} having intervals of: #{interval}"
    end

    def validate_parameters(params)
      table_name = params.fetch(:table_name)
      return if approved_tables.include?(table_name) &&
                additional_validators.all? { |validator| validator.call(params, logger) }

      raise PgDice::IllegalTableError, "Table: #{table_name} is not in the list of approved tables!"
    end

    private

    def logger
      @configuration.logger
    end

    def additional_validators
      return @configuration.additional_validators if @configuration.additional_validators.is_a?(Array)
      raise PgDice::InvalidConfigurationError, 'additional_validators must be an array!'
    end

    def database_connection
      return @configuration.database_connection if @configuration.database_connection
      raise PgDice::InvalidConfigurationError, 'database_connection must be present!'
    end

    def approved_tables
      return @configuration.approved_tables if @configuration.approved_tables.is_a?(Array)
      raise PgDice::InvalidConfigurationError, 'approved_tables must be an array of strings!'
    end

    def build_assert_sql(table_name, future_tables, interval)
      <<~SQL
        SELECT 1
        FROM pg_catalog.pg_class pg_class
        INNER JOIN pg_catalog.pg_namespace pg_namespace ON pg_namespace.oid = pg_class.relnamespace
        WHERE pg_class.relkind = 'r'
          AND pg_namespace.nspname = 'public'
          AND pg_class.relname = '#{table_name}_' || to_char(NOW()
            + INTERVAL '#{future_tables} #{interval}', 'YYYYMMDD')
      SQL
    end
  end
end
