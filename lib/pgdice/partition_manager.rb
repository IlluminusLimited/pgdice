# frozen_string_literal: true

# Entry point for PartitionManager
module PgDice
  #  PartitionManager is a class used to fulfill high-level tasks for partitioning
  class PartitionManager
    include PgDice::Loggable
    extend Forwardable
    def_delegators :@configuration, :older_than, :table_drop_batch_size, :approved_tables

    attr_reader :validation, :pg_slice_manager, :database_connection

    def initialize(configuration = PgDice::Configuration.new, opts = {})
      @configuration = configuration
      @logger = opts[:logger]
      @validation = PgDice::Validation.new(configuration)
      @pg_slice_manager = PgDice::PgSliceManager.new(configuration)
      @database_connection = PgDice::DatabaseConnection.new(configuration)
    end

    def add_new_partitions(params = {})
      logger.info { "add_new_partitions has been called with params: #{params}" }

      validation.validate_parameters(params)
      pg_slice_manager.add_partitions(params)
    end

    def drop_old_partitions(params = {})
      logger.info { "drop_old_partitions has been called with params: #{params}" }

      validation.validate_parameters(params)
      old_partitions = list_droppable_tables(params)
      logger.warn { "Partitions to be deleted are: #{old_partitions}" }

      old_partitions.each do |old_partition|
        @configuration.table_dropper.call(old_partition, logger)
      end
      old_partitions
    end

    # Grabs only tables that start with the base_table_name and end in numbers
    def list_partitions(params = {})
      table_name = params.fetch(:table_name)
      schema = params.fetch(:schema, 'public')
      older_than = params[:older_than]

      validation.validate_parameters(params)

      logger.info { "Fetching partition tables with params: #{params}" }

      sql = build_partition_table_fetch_sql(params)

      partition_tables = database_connection.execute(sql).values.flatten
      logger.debug { "Table: #{schema}.#{table_name} has partition_tables: #{partition_tables}" }
      if older_than
        filtered_partitions = filter_partitions(partition_tables, table_name, older_than)
        logger.debug do
          "Filtered partitions for table: #{schema}.#{table_name} and "\
            "older_than: #{older_than} are: #{filtered_partitions}"
        end
      end
      partition_tables
    end

    def list_droppable_tables(params = {})
      table_name = params.fetch(:table_name)
      batch_size = params.fetch(:table_drop_batch_size, table_drop_batch_size)
      older_than = params.fetch(:older_than).to_date
      minimum_tables = approved_tables.fetch(table_name).past
      current_date = Date.today.to_date

      logger.debug do
        "Checking if the minimum_table_threshold of #{minimum_tables} tables for base_table: #{table_name} "\
        "will not be exceeded. Looking back from: #{current_date}"
      end

      if older_than > current_date
        raise ArgumentError, "Cannot drop tables that are not older than the current date: #{current_date}"
      end

      eligible_partitions = list_partitions(table_name: table_name, older_than: current_date)
      selected_partitions = filter_partitions(eligible_partitions, table_name, older_than)
      tables_to_drop = batch_size > selected_partitions.size ? selected_partitions.size : batch_size
      tables_to_drop = (eligible_partitions.size - tables_to_drop) < minimum_tables ? tables_to_drop - minimum_tables + 1 : tables_to_drop

      if (eligible_partitions.size - tables_to_drop) < minimum_tables
        logger.warn do
          "Attempt to drop #{tables_to_drop} tables from #{table_name} would result in "\
"#{eligible_partitions.size - tables_to_drop} remaining tables which exceeds the "\
"minimum_table_threshold of #{minimum_tables}. Table dropping will not occur."
        end
        return []
      end
      droppable_tables = selected_partitions.first(tables_to_drop)
      logger.debug { "Partitions eligible for dropping are: #{droppable_tables}" }
      droppable_tables
    end

    private

    def filter_partitions(partition_tables, base_table_name, partitions_older_than_date)
      partition_tables.select do |partition_name|
        partition_created_at_time = Date.parse(partition_name.gsub(/#{base_table_name}_/, ''))
        partition_created_at_time < partitions_older_than_date.to_date
      end
    end

    def build_partition_table_fetch_sql(params = {})
      schema = params.fetch(:schema, 'public')
      base_table_name = params.fetch(:table_name)

      <<~SQL
        SELECT tablename
        FROM pg_tables
        WHERE schemaname = '#{schema}'
          AND tablename ~ '^#{base_table_name}_\\d+$'
        ORDER BY tablename
      SQL
    end
  end
end
