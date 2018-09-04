# frozen_string_literal: true

# Entry point for PreparationHelper
module PgDice
  # Helps do high-level tasks like getting tables partitioned
  class PreparationHelper
    def initialize(configuration = Configuration.new)
      @configuration = configuration
    end

    def prepare_database!(opts = {})
      opts[:column_name] ||= 'created_at'
      opts[:period] ||= 'day'
      logger.info {"Preparing database with params: #{opts}"}

      prep_and_fill(opts)
      swap_and_fill(opts)
    end

    def cleanup_database!(table_name)
      logger.info {"Cleaning up database with params: #{table_name}"}

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
