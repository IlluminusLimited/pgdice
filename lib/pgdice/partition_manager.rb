# frozen_string_literal: true

# Entry point for PartitionManager
module PgDice
  #  PartitionManager is a class used to fulfill high-level tasks for partitioning
  class PartitionManager
    include PgDice::Loggable
    extend Forwardable
    include TableFinder

    def_delegators :@configuration, :older_than, :table_drop_batch_size, :approved_tables

    attr_reader :validation, :pg_slice_manager, :database_connection

    def initialize(configuration = PgDice::Configuration.new, opts = {})
      @configuration = configuration
      @logger = opts[:logger]
      @current_date_provider = opts[:current_date_provider] ||= proc { Date.today.to_date }
      @validation = PgDice::Validation.new(configuration)
      @pg_slice_manager = PgDice::PgSliceManager.new(configuration)
      @database_connection = PgDice::DatabaseConnection.new(configuration)
    end

    def add_new_partitions(table_name, params = {})
      all_params = approved_tables.smash(table_name, params)
      logger.debug { "add_new_partitions has been called with params: #{all_params}" }
      validation.validate_parameters(all_params)
      pg_slice_manager.add_partitions(all_params)
    end

    def drop_old_partitions(table_name, params = {})
      all_params = approved_tables.smash(table_name, params)
      all_params[:older_than] = @current_date_provider.call
      logger.debug { "drop_old_partitions has been called with params: #{all_params}" }

      validation.validate_parameters(all_params)
      old_partitions = list_droppable_tables(table_name, all_params)
      handle_partition_dropping(old_partitions)
    end

    # Grabs only tables that start with the base_table_name and end in numbers
    def list_partitions(table_name, params = {})
      table = approved_tables.fetch(table_name)
      all_params = table.smash(params)
      older_than = all_params[:older_than]

      validation.validate_parameters(all_params)

      logger.info { "Fetching partition tables with params: #{all_params}" }

      sql = build_partition_table_fetch_sql(all_params)

      partition_tables = database_connection.execute(sql).values.flatten
      handle_returned_partitions(table, partition_tables, older_than)
    end

    def list_droppable_tables(table_name, params = {})
      table, batch_size, older_than, minimum_tables, current_date = populate_variables(table_name, params)

      logger.debug do
        "Checking if the minimum_table_threshold of #{minimum_tables} tables for base_table: #{table.name} "\
        "will not be exceeded. Looking back from: #{current_date}"
      end

      validation.validate_dates(current_date, older_than)

      process_droppable_tables(older_than, current_date, batch_size, minimum_tables, table)
    end
  end
end
