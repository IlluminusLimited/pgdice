# frozen_string_literal: true

# Entry point for PartitionHelper
module PgDice
  # Helps do high-level tasks like getting tables partitioned
  class PartitionHelper
    extend Forwardable
    def_delegators :@configuration, :logger

    attr_reader :pg_slice_manager, :validation_helper

    def initialize(configuration = PgDice::Configuration.new)
      @configuration = configuration
      @pg_slice_manager = PgDice::PgSliceManager.new(configuration)
      @validation_helper = PgDice::Validation.new(configuration)
    end

    def partition_table!(params = {})
      params[:column_name] ||= 'created_at'
      params[:period] ||= 'day'
      logger.info { "Preparing database with params: #{params}" }

      prep_and_fill(params)
      swap_and_fill(params)
    end

    def undo_partitioning!(params = {})
      table_name = params.fetch(:table_name)
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
