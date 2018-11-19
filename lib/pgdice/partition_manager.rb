# frozen_string_literal: true

# Entry point for PartitionManager
module PgDice
  #  PartitionManager is a class used to fulfill high-level tasks for partitioning
  class PartitionManager
    include PgDice::Loggable
    include PgDice::TableFinder
    extend Forwardable

    def_delegators :@configuration, :approved_tables, :database_connection

    attr_reader :validation

    def initialize(configuration = PgDice::Configuration.new, opts = {})
      @configuration = configuration
      @logger = opts[:logger]
      @current_date_provider = opts[:current_date_provider] ||= proc { Time.now.utc.to_date }
      @validation = PgDice::Validation.new(configuration)
      @partition_lister = opts[:partition_lister] ||= ->(all_params) do
        PgDice::PartitionLister.new(database_connection: database_connection).call(all_params)
      end
      @partition_adder = opts[:partition_adder] ||= ->(all_params) do
        PgDice::PgSliceManager.new(@configuration).add_partitions(all_params)
      end
      @partition_dropper = opts[:partition_dropper] ||= ->(all_params) do
        old_partitions = list_droppable_partitions(all_params[:table_name], all_params)
        @configuration.table_dropper.call(old_partitions)
      end
    end

    def add_new_partitions(table_name, params = {})
      all_params = approved_tables.smash(table_name, params)
      logger.debug { "add_new_partitions has been called with params: #{all_params}" }
      validation.validate_parameters(all_params)
      @partition_adder.call(all_params)
    end

    def drop_old_partitions(table_name, params = {})
      all_params = approved_tables.smash(table_name, params)
      all_params[:older_than] = @current_date_provider.call
      logger.debug { "drop_old_partitions has been called with params: #{all_params}" }

      validation.validate_parameters(all_params)
      @partition_dropper.call(all_params)
    end

    # Grabs only tables that start with the base_table_name and end in numbers
    def list_partitions(table_name, params = {})
      all_params = approved_tables.smash(table_name, params)
      validation.validate_parameters(all_params)
      partitions(all_params)
    end

    def list_droppable_partitions(table_name, params = {})
      all_params = approved_tables.smash(table_name, params)
      validation.validate_parameters(all_params)
      droppable_partitions(all_params)
    end

    def list_batched_droppable_partitions(table_name, params = {})
      all_params = approved_tables.smash(table_name, params)
      validation.validate_parameters(all_params)
      droppable_tables = batched_droppable_partitions(all_params)
      logger.debug { "Batched partitions eligible for dropping are: #{droppable_tables}" }
      droppable_tables
    end


    private

    def partitions(all_params)
      logger.info { "Fetching partition tables with params: #{all_params}" }
      @partition_lister.call(all_params)
    end

    def droppable_partitions(all_params)
      older_than = @current_date_provider.call
      minimum_tables = all_params.fetch(:past)

      eligible_partitions = partitions(all_params)

      droppable_tables = find_droppable_partitions(eligible_partitions, older_than, minimum_tables)
      logger.debug { "Partitions eligible for dropping older than: #{older_than} are: #{droppable_tables}" }
      droppable_tables
    end

    def batched_droppable_partitions(all_params)
      batch_size = all_params.fetch(:batch_size, @configuration.batch_size)
      selected_partitions = droppable_partitions(all_params)
      batched_tables(selected_partitions, batch_size)
    end
  end
end
