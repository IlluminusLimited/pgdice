# frozen_string_literal: true

module PgDice
  # Collection of utilities that provide ways for users to ensure things are working properly
  class Validation
    attr_reader :logger, :database_connection, :approved_tables

    def initialize(logger, database_connection, approved_tables)
      @logger = params[:logger]
      @database_connection = database_connection
      @approved_tables = approved_tables
    end

    def assert_tables(table_name, params)
      unless params[:future] || params[:past]
        raise ArgumentError, 'You must provide either a future or past number of tables to assert on.'
      end

      table = approved_tables.fetch(table_name)
      period = resolve_period(table_name: table_name, **params)

      all_params = table.smash(params.merge!(period: period))
      validate_parameters(all_params)
      logger.debug { "Running asserts on table: #{table} with params: #{all_params}" }
      run_asserts(table.name, period, params)
    end

    def validate_parameters(params)
      validate_table_name(params)
      validate_period(params)

      true
    end

    def validate_dates(current_date, older_than)
      if older_than > current_date
        raise ArgumentError, "Cannot list tables that are not older than the current date: #{current_date}"
      end

      true
    end

    private

    def run_asserts(table_name, period, params)
      assert_future_tables(table_name, params[:future], period) if params[:future]
      assert_past_tables(table_name, params[:past], period) if params[:past]
      true
    end

    def resolve_period(params)
      validate_period(params) if params[:period]
      period = fetch_period_from_table_comment(params.fetch(:table_name))

      # If the user doesn't supply a period and we fail to find one on the table then it's a pretty good bet
      # this table is not partitioned at all.
      unless period
        raise TableNotPartitionedError,
              "Table: #{params.fetch(:table_name)} is not partitioned! Cannot validate partitions that don't exist!"
      end
      validate_period(period: period)
      period
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

      unless PgDice::SUPPORTED_PERIODS.include?(params[:period].to_s)
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

      raise PgDice::InsufficientPastTablesError.new(table_name, "Expected: #{past} having period of: #{period}.")
    end

    def build_assert_sql(table_name, table_count, period, direction)
      add_or_subtract = { future: '+', past: '-' }.fetch(direction, '-')
      <<~SQL
        SELECT 1
        FROM pg_catalog.pg_class pg_class
        INNER JOIN pg_catalog.pg_namespace pg_namespace ON pg_namespace.oid = pg_class.relnamespace
        WHERE pg_class.relkind = 'r'
          AND pg_namespace.nspname = 'public'
          AND pg_class.relname = '#{table_name}_' || to_char(NOW()
            #{add_or_subtract} INTERVAL '#{table_count} #{period}', '#{SUPPORTED_PERIODS[period.to_s]}')
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
      "SELECT obj_description('#{schema}.#{table_name}'::REGCLASS) AS comment"
    end
  end
end
