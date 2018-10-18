# frozen_string_literal: true

# Entry point for PartitionHelper
module PgDice
  # Helps do high-level tasks like getting tables partitioned
  class PartitionHelper
    include PgDice::Loggable
    extend Forwardable

    def_delegators :@configuration, :approved_tables

    attr_reader :pg_slice_manager, :validation_helper

    def initialize(configuration = PgDice::Configuration.new, opts = {})
      @configuration = configuration
      @logger = opts[:logger]
      @pg_slice_manager = PgDice::PgSliceManager.new(configuration)
      @validation_helper = PgDice::Validation.new(configuration)
    end

    def partition_table!(table_name, params = {})
      table = approved_tables.fetch(table_name)
      table.validate!
      all_params = table.to_h.merge(params)
      validation_helper.validate_parameters(all_params)

      logger.info { "Preparing database for table: #{table}" }

      prep_and_fill(all_params)
      swap_and_fill(all_params)
    end

    def undo_partitioning!(table_name)
      approved_tables.fetch(table_name)
      logger.info { "Cleaning up database with params: #{table_name}" }

      pg_slice_manager.analyze(table_name: table_name, swapped: true)
      pg_slice_manager.unswap!(table_name: table_name)
      pg_slice_manager.unprep!(table_name: table_name)
    end

    def partition_table(params = {})
      partition_table!(params)
    rescue PgDice::PgSliceError => error
      logger.error { "Rescued PgSliceError: #{error}" }
      false
    end

    def undo_partitioning(params = {})
      undo_partitioning!(params)
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
