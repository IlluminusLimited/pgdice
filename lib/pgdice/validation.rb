# frozen_string_literal: true

module PgDice
  # Collection of utilities that provide ways for users to ensure things are working properly
  class Validation
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

      return if additional_validators.all? { |validator| validator.call(params, logger) }
      raise PgDice::CustomValidationError,
            "Custom validation failed with params: #{params}. "\
            "Validators: #{additional_validators.map { |validator| source_location(validator) }}"
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

    def source_location(proc)
      return proc.source_location if proc.respond_to?(:source_location)
      proc.to_s
    end
  end
end
