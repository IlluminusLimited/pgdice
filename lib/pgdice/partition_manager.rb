# frozen_string_literal: true

require 'pgdice/helpers/validation_helper'

# Entry point for PartitionManager
module PgDice
  #  PartitionManager is a class used to fulfill high-level tasks for partitioning
  class PartitionManager
    def initialize(configuration = Configuration.new)
      @configuration = configuration
    end

    def prepare_database!(opts = {})
      opts[:column_name] ||= 'created_at'
      opts[:period] ||= 'day'

      prep_and_fill(opts)
      swap_and_fill(opts)
    end

    def cleanup_database!(table_name)
      pg_slice_manager.analyze(table_name: table_name, swapped: true)
      pg_slice_manager.unswap!(table_name: table_name)
      pg_slice_manager.unprep!(table_name: table_name)
    end

    def cleanup_database(table_name)
      cleanup_database!(table_name)
    rescue PgSliceError => error
      logger.error { "Rescued PgSliceError: #{error}" }
      false
    end

    def add_new_partitions(params = {})
      validation_helper.validate_parameters(params)
      pg_slice_manager.add_partitions(params)
    end

    def delete_old_partitions(params = {})
      validation_helper.validate_parameters(params)
      # this wont use pg_slice
    end

    def discover_old_partitions(table_name)
      validation_helper.validate_parameters(table_name: table_name)
      partition_tables = fetch_partition_tables(table_name)
      current_date = Date.current

      partition_tables.select do |partition_name|
        date = Date.parse(partition_name.gsub(/#{table_name}_/, ''))
        date < current_date
      end
    end

    private

    def prep_and_fill(opts)
      pg_slice_manager.prep(opts)
      pg_slice_manager.add_partitions(opts.merge!(intermediate: true))
      pg_slice_manager.fill(opts) if opts[:fill]
    end

    def swap_and_fill(opts)
      pg_slice_manager.analyze(opts)
      pg_slice_manager.swap(opts)
      pg_slice_manager.fill(opts.merge!(swapped: true)) if opts[:fill]
    end

    def logger
      @configuration.logger
    end

    def pg_slice_manager
      @configuration.pg_slice_manager
    end

    def validation_helper
      @configuration.validation_helper
    end
  end
end
