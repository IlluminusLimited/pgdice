# frozen_string_literal: true

module PgDice
  # Collection of utilities that provide ways for users to ensure things are working properly
  class Validation
    extend Forwardable
    def_delegators :@configuration, :logger, :additional_validators, :database_connection, :approved_tables

    def initialize(configuration = PgDice::Configuration.new)
      @configuration = configuration
    end

    def assert_future_tables(params = {})
      table_name = params.fetch(:table_name)
      future = params.fetch(:future)
      period = params.fetch(:period, 'day')

      sql = build_assert_sql(table_name, future, period)

      response = database_connection.execute(sql)

      return true if response.values.size == 1
      raise PgDice::InsufficientFutureTablesError, "Insufficient future tables exist for table: #{table_name}. "\
"Expected: #{future} having period of: #{period}"
    end

    def validate_parameters(params)
      table_name = params.fetch(:table_name)
      unless approved_tables.include?(table_name)
        raise PgDice::IllegalTableError, "Table: #{table_name} is not in the list of approved tables!"
      end

      begin
        return true if additional_validators.all? { |validator| validator.call(params, logger) }
        raise PgDice::CustomValidationError.new(params, additional_validators)
      rescue StandardError => error
        raise PgDice::CustomValidationError.new(params, additional_validators, error)
      end
    end

    private

    def build_assert_sql(table_name, future_tables_count, period)
      <<~SQL
        SELECT 1
        FROM pg_catalog.pg_class pg_class
        INNER JOIN pg_catalog.pg_namespace pg_namespace ON pg_namespace.oid = pg_class.relnamespace
        WHERE pg_class.relkind = 'r'
          AND pg_namespace.nspname = 'public'
          AND pg_class.relname = '#{table_name}_' || to_char(NOW()
            + INTERVAL '#{future_tables_count} #{period}', 'YYYYMMDD')
      SQL
    end
  end
end
