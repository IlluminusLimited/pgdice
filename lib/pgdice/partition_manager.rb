# frozen_string_literal: true

# Entry point for PartitionManager
module PgDice
  #  PartitionManager is a class used to fulfill high-level tasks for partitioning
  class PartitionManager
    attr_reader :logger
    APPROVED_TABLES ||= ENV['PG_DICE_PARTITIONED_TABLES']&.slice(',')

    def initialize(configuration = Configuration.new)
      @logger = configuration.logger
      @pg_slice_manager = configuration.pg_slice_manager
    end

    def prepare_database!(table_name, opts = {})
      column_name = opts[:column_name] ||= 'created_at'
      period = opts[:period] ||= 'day'
      future = opts[:future]
      past = opts[:past]
      fill = opts[:fill]

      @pg_slice_manager.prep(table_name: table_name, column_name: column_name, period: period)
      @pg_slice_manager.add_partitions(table_name: table_name, future: future, past: past, intermediate: true)
      @pg_slice_manager.fill(table_name: table_name) if fill.present?
      @pg_slice_manager.analyze(table_name: table_name)
      @pg_slice_manager.swap(table_name: table_name)
      @pg_slice_manager.fill(table_name: table_name, swapped: true) if fill.present?
    end

    def cleanup_database!(table_name)
      @pg_slice_manager.analyze(table_name: table_name, swapped: true)
      @pg_slice_manager.unswap!(table_name: table_name)
      @pg_slice_manager.unprep!(table_name: table_name)
    end

    def cleanup_database(table_name)
      cleanup_database!(table_name)
    rescue PgSliceError => error
      logger.error { "Rescued PgSliceError: #{error}" }
      false
    end

    def add_new_partitions(params = {})
      validate_parameters(params)
      @pg_slice_manager.add_partitions(params)
    end

    def delete_old_partitions(params = {})
      validate_parameters(params)
      # this wont use pg_slice
    end

    def discover_old_partitions(table_name)
      validate_parameters(table_name: table_name)
      partition_tables = fetch_partition_tables(table_name)
      current_date = Date.current

      partition_tables.select do |partition_name|
        date = Date.parse(partition_name.gsub(/#{table_name}_/, ''))
        date < current_date
      end
    end
  end
end
