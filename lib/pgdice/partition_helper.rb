# frozen_string_literal: true

# Entry point for PartitionHelper
module PgDice
  # Helps do high-level tasks like getting tables partitioned
  class PartitionHelper
    attr_reader :logger, :approved_tables, :validation, :pg_slice_manager

    def initialize(logger:, approved_tables:, validation:, pg_slice_manager:)
      @logger = logger
      @validation = validation
      @approved_tables = approved_tables
      @pg_slice_manager = pg_slice_manager
    end

    def partition_table(table_name, params = {})
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
      unswap_results = unswap(table_name)
      unprep_results = unprep(table_name)
      if !unswap_results && !unprep_results
        raise PgDice::PgSliceError, "Unswapping and unprepping failed for table: #{table_name}"
      end

      true
    end

    def undo_partitioning(table_name)
      undo_partitioning!(table_name)
    rescue PgDice::PgSliceError => error
      logger.error { "Rescued PgSliceError: #{error}" }
      false
    end

    private

    def unswap(table_name)
      unswap_results = pg_slice_manager.unswap(table_name: table_name)
      logger.warn { "Unswapping #{table_name} was not successful. " } unless unswap_results
      unswap_results
    end

    def unprep(table_name)
      unprep_results = pg_slice_manager.unprep(table_name: table_name)
      logger.warn { "Unprepping #{table_name} was not successful." } unless unprep_results
      unprep_results
    end

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
