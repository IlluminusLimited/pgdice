# frozen_string_literal: true

# Entry point for PartitionManager
module PgDice
  #  PartitionManager is a class used to fulfill high-level tasks for partitioning
  class PartitionManager
    include PgDice::Loggable
    extend Forwardable

    def_delegators :@configuration, :batch_size, :approved_tables, :table_dropper

    attr_reader :validation, :pg_slice_manager, :database_connection

    def initialize(configuration = PgDice::Configuration.new, opts = {})
      @configuration = configuration
      @logger = opts[:logger]
      @current_date_provider = opts[:current_date_provider] ||= proc { Time.now.utc.to_date }
      @validation = PgDice::Validation.new(configuration)
      @pg_slice_manager = PgDice::PgSliceManager.new(configuration)
      @database_connection = PgDice::DatabaseConnection.new(configuration)
      @table_finder = PgDice::TableFinder.new(configuration)
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
      old_partitions = list_droppable_partitions(table_name, all_params)
      handle_partition_dropping(old_partitions)
    end

    # Grabs only tables that start with the base_table_name and end in numbers
    def list_partitions(table_name, params = {})
      table = approved_tables.fetch(table_name)
      all_params = table.smash(params)
      older_than = all_params[:older_than]

      validation.validate_parameters(all_params)

      logger.info { "Fetching partition tables with params: #{all_params}" }

      sql = @table_finder.build_partition_table_fetch_sql(all_params)

      partition_tables = database_connection.execute(sql).values.flatten
      logger.debug { "Table: #{table} has partition_tables: #{partition_tables}" }
      if older_than
        partition_tables = partition_tables.select do |partition_name|
          partition_created_at_time = Date.parse(partition_name.gsub(/#{table.name}_/, ''))
          partition_created_at_time < older_than.to_date
        end
        logger.debug do
          "Filtered partitions for table: #{table.full_name} and older_than: #{older_than} are: #{partition_tables}"
        end
      end
      partition_tables
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

      selected_partitions = eligible_partitions.select do |partition_name|
        partition_created_at_time = Date.parse(partition_name.gsub(/#{table.name}_/, ''))
        partition_created_at_time < older_than.to_date
      end

      expected_tables_to_drop = batch_size > selected_partitions.size ? selected_partitions.size : batch_size
      remaining_partitions = eligible_partitions.size - expected_tables_to_drop

      tables_to_drop = if remaining_partitions < minimum_tables
                         expected_tables_to_drop - minimum_tables
                       else
                         expected_tables_to_drop
                       end
      tables_to_drop = tables_to_drop.abs
      remaining_partitions = eligible_partitions.size - tables_to_drop
      if remaining_partitions < minimum_tables
        logger.warn do
          "Attempt to drop #{tables_to_drop} tables from #{table.full_name} would result in "\
"#{remaining_partitions} remaining tables which violates the minimum past of #{minimum_tables}. Not dropping tables."
        end
        return []
      end
      droppable_tables = selected_partitions.first(tables_to_drop)
      logger.debug { "Partitions eligible for dropping are: #{droppable_tables}" }
      droppable_tables
    end

    private

    def handle_partition_dropping(old_partitions)
      logger.info { "Partitions to be deleted are: #{old_partitions}" }

      old_partitions.each do |old_partition|
        table_dropper.call(old_partition, logger)
      end
      old_partitions
    end
  end
end
