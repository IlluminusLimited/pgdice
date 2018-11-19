# frozen_string_literal: true

# Entry point for PartitionManager
module PgDice
  #  PartitionManager is a class used to fulfill high-level tasks for partitioning
  class PartitionManager
    include PgDice::Loggable
    include PgDice::TableFinder
    extend Forwardable

    def_delegators :@configuration, :batch_size, :approved_tables, :database_connection

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
        old_partitions = list_droppable_partitions(table_name, all_params)
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
      table = approved_tables.fetch(table_name)
      all_params = table.smash(params)

      validation.validate_parameters(all_params)

      logger.info { "Fetching partition tables with params: #{all_params}" }

     @partition_lister.call(all_params)
    end

    def list_droppable_partitions(table_name, params = {})
      table = approved_tables.fetch(table_name)
      all_params = table.smash(params)
      current_date = @current_date_provider.call

      batch_size = all_params.fetch(:batch_size, @configuration.batch_size)
      older_than = all_params.fetch(:older_than, Time.now.utc).to_date
      minimum_tables = all_params[:past]

      logger.debug do
        "Checking if the minimum_table_threshold of #{minimum_tables} tables for base_table: #{table.name} "\
        "will not be exceeded. Looking back from: #{current_date}"
      end

      validation.validate_dates(current_date, older_than)
      eligible_partitions = list_partitions(table.name, older_than: current_date)

      droppable_tables = find_droppable_partitions(eligible_partitions, older_than, minimum_tables)

      logger.debug { "Partitions eligible for dropping are: #{droppable_tables}" }
      droppable_tables
    end

  end
end
