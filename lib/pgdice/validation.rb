# frozen_string_literal: true

module PgDice
  # Collection of utilities that provide ways for users to ensure things are working properly
  class Validation
    include PgDice::TableFinder

    attr_reader :logger, :approved_tables

    def initialize(logger:, partition_lister:, period_fetcher:, approved_tables:, current_date_provider:)
      @logger = logger
      @approved_tables = approved_tables
      @partition_lister = partition_lister
      @period_fetcher = period_fetcher
      @current_date_provider = current_date_provider
    end

    def assert_tables(table_name, opts = nil)
      table, period, all_params, params = filter_parameters(approved_tables.fetch(table_name), opts)
      validate_parameters(all_params)
      logger.debug { "Running asserts on table: #{table} with params: #{all_params}" }

      partitions = @partition_lister.call(all_params)

      assert_future_tables(table_name, partitions, period, params[:future]) if params && params[:future]
      assert_past_tables(table_name, partitions, period, params[:past]) if params && params[:past]
      true
    end

    def validate_parameters(params)
      validate_table_name(params)
      validate_period(params)

      true
    end

    private

    def filter_parameters(table, params)
      if params.nil?
        params, period = handle_nil_params(table)
      else
        handle_only_param(table, params) if params[:only]
        period = resolve_period(schema: table.schema, table_name: table.name, **params)
      end

      all_params = table.smash(params.merge!(period: period))

      [table, period, all_params, params]
    end

    def handle_nil_params(table)
      params = {}
      params[:future] = table.future
      params[:past] = table.past
      [params, table.period]
    end

    def handle_only_param(table, params)
      params[:future] = params[:only] == :future ? params[:future] || table.future : nil
      params[:past] = params[:only] == :past ? params[:past] || table.past : nil
    end

    def assert_future_tables(table_name, partitions, period, expected)
      newer_tables = tables_newer_than(partitions, @current_date_provider.call, period).size
      if newer_tables < expected
        raise PgDice::InsufficientFutureTablesError.new(table_name, expected, period, newer_tables)
      end

      true
    end

    def assert_past_tables(table_name, partitions, period, expected)
      older_tables = tables_older_than(partitions, @current_date_provider.call, period).size
      if older_tables < expected
        raise PgDice::InsufficientPastTablesError.new(table_name, expected, period, older_tables)
      end

      true
    end

    def resolve_period(params)
      validate_period(params) if params[:period]
      period = @period_fetcher.call(params)

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
  end
end
