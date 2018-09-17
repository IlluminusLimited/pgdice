# frozen_string_literal: true

module PgDice
  # Collection of utilities that provide ways for users to ensure things are working properly
  class Validation
    extend Forwardable
    def_delegators :@configuration, :logger, :additional_validators, :database_connection, :approved_tables

    def initialize(configuration = PgDice::Configuration.new)
      @configuration = configuration
    end

    def assert_tables(params = {})
      unless params[:future] || params[:past]
        raise ArgumentError, 'You must provide either a future or past number of tables to assert on.'
      end

      table_name = validate_table_name(params)
      period = resolve_period(params)

      assert_future_tables(table_name, params[:future], period) if params[:future]
      assert_past_tables(table_name, params[:past], period) if params[:past]
      true
    end

    def validate_parameters(params)
      validate_table_name(params)
      validate_period(params)

      run_additional_validators(params)
      true
    end

    private

    def resolve_period(params)
      period = validate_period(params) || fetch_period_from_table_comment(params.fetch(:table_name))

      unless period
        raise TableNotPartitionedError,
              "Table: #{params.fetch(:table_name)} is not partitioned! Cannot validate partitions that don't exist!"
      end
      period
    end

    def run_additional_validators(params)
      return true if additional_validators.all? { |validator| validator.call(params, logger) }

      raise PgDice::CustomValidationError.new(params, additional_validators)
    rescue StandardError => error
      raise PgDice::CustomValidationError.new(params, additional_validators, error)
    end

    def validate_table_name(params)
      table_name = params.fetch(:table_name)
      unless approved_tables.include?(table_name)
        raise PgDice::IllegalTableError, "Table: #{table_name} is not in the list of approved tables!"
      end

      table_name
    end

    def validate_period(params)
      return unless params[:period]

      unless PgDice::SUPPORTED_PERIODS.include?(params[:period])
        raise ArgumentError,
              "Period must be one of: #{PgDice::SUPPORTED_PERIODS.keys}. Value: #{params[:period]} is not valid."
      end

      params[:period].to_sym
    end

    def assert_future_tables(table_name, future, period)
      sql = build_assert_sql(table_name, future, period, :future)

      response = database_connection.execute(sql)

      return true if response.values.size == 1

      raise PgDice::InsufficientFutureTablesError.new(table_name, future, period)
    end

    def assert_past_tables(table_name, past, period)
      sql = build_assert_sql(table_name, past, period, :past)

      response = database_connection.execute(sql)

      return true if response.values.size == 1

      raise PgDice::InsufficientPastTablesError.new(table_name, past, period)
    end

    def build_assert_sql(table_name, table_count, period, direction)
      add_or_subtract = { future: '+', past: '-' }.fetch(direction, '+')
      <<~SQL
        SELECT 1
        FROM pg_catalog.pg_class pg_class
        INNER JOIN pg_catalog.pg_namespace pg_namespace ON pg_namespace.oid = pg_class.relnamespace
        WHERE pg_class.relkind = 'r'
          AND pg_namespace.nspname = 'public'
          AND pg_class.relname = '#{table_name}_' || to_char(NOW()
            #{add_or_subtract} INTERVAL '#{table_count} #{period}', '#{SUPPORTED_PERIODS[period.to_sym]}')
      SQL
    end

    def fetch_period_from_table_comment(table_name)
      sql = build_table_comment_sql(table_name, 'public')
      values = database_connection.execute(sql).values.flatten.compact
      convert_comment_to_hash(values.first)[:period]
    end

    def convert_comment_to_hash(comment)
      return {} unless comment
      partition_template = {}
      comment.split(',').each do |key_value_pair|
        key, value = key_value_pair.split(':')
        partition_template[key.to_sym] = value
      end
      partition_template
    end

    def build_table_comment_sql(table_name, schema)
      <<~SQL
        SELECT obj_description('#{schema}.#{table_name}'::REGCLASS) AS comment
      SQL
    end
  end
end
