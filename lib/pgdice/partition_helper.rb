# frozen_string_literal: true

# Entry point for PartitionHelper
module PgDice
  # Helps do high-level tasks like getting tables partitioned
  class PartitionHelper
    attr_reader :logger, :validation, :pg_slice_manager

    def initialize(logger:, validation:, pg_slice_manager:)
      @logger = logger
      @validation = validation
      @pg_slice_manager = pg_slice_manager
    end

    def partition_table!(table_name, params = {})
      table = approved_tables.fetch(table_name)
      all_params = table.smash(params)
      validation.validate_parameters(all_params)

      logger.info { "Preparing database for table: #{table}. Using parameters: #{all_params}" }

      prep_and_fill(all_params)
      swap_and_fill(all_params)
    end

    def undo_partitioning!(table_name)
      approved_tables.fetch(table_name)
      logger.info { "Undoing partitioning for table: #{table_name}" }

      pg_slice_manager.analyze(table_name: table_name, swapped: true)
      pg_slice_manager.unswap!(table_name: table_name)
      pg_slice_manager.unprep!(table_name: table_name)
    end

    def partition_table(table_name, params = {})
      partition_table!(table_name, params)
    rescue PgDice::PgSliceError => error
      logger.error { "Rescued PgSliceError: #{error}" }
      false
    end

    def undo_partitioning(table_name)
      undo_partitioning!(table_name)
    rescue PgDice::PgSliceError => error
      logger.error { "Rescued PgSliceError: #{error}" }
      false
    end

    private

    def prep_and_fill(params)
      pg_slice_manager.prep(params)
      pg_slice_manager.add_partitions(params.merge!(intermediate: true))
      pg_slice_manager.fill(params) if params[:fill]
    end

    def swap_and_fill(params)
      pg_slice_manager.analyze(params)
      pg_slice_manager.swap(params)
      pg_slice_manager.fill(params.merge!(swapped: true)) if params[:fill]
    end
  end
end
