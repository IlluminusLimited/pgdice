# frozen_string_literal: true

# Entry point for PartitionManager
module PgDice
  #  PartitionManager is a class used to fulfill high-level tasks for partitioning
  class PartitionManager
    extend Forwardable
    def_delegators :@configuration, :logger, :older_than, :table_drop_batch_size

    attr_reader :validation, :pg_slice_manager, :database_connection

    def initialize(configuration = PgDice::Configuration.new)
      @configuration = configuration
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
      old_partitions = list_old_partitions(params)
      logger.warn { "Partitions to be deleted are: #{old_partitions}" }

      old_partitions.each do |old_partition|
        @configuration.table_dropper.call(old_partition, logger)
      end
      old_partitions
    end

    def list_old_partitions(params = {})
      params[:older_than] ||= older_than
      logger.info { "Listing old partitions with params: #{params}" }

      validation.validate_parameters(params)

      partition_tables = fetch_partition_tables(params)

      filter_partitions(partition_tables, params[:table_name], params[:older_than])
    end

    # Grabs only tables that start with the base_table_name and end in numbers
    def fetch_partition_tables(params = {})
      schema = params[:schema] ||= 'public'
      logger.info { "Fetching partition tables with params: #{params}" }

      sql = build_partition_table_fetch_sql(params)

      partition_tables = database_connection.execute(sql).values.flatten
      logger.debug { "Table: #{schema}.#{params[:table_name]} has partition_tables: #{partition_tables}" }
      partition_tables
    end

    private

    def filter_partitions(partition_tables, base_table_name, partitions_older_than_time)
      partition_tables.select do |partition_name|
        partition_created_at_date = Date.parse(partition_name.gsub(/#{base_table_name}_/, '')).to_time
        partition_created_at_date < partitions_older_than_time
      end
    end

    def build_partition_table_fetch_sql(params = {})
      schema = params.fetch(:schema)
      base_table_name = params.fetch(:table_name)
      limit = params.fetch(:limit, table_drop_batch_size)

      <<~SQL
        SELECT tablename
        FROM pg_tables
        WHERE schemaname = '#{schema}'
          AND tablename ~ '^#{base_table_name}_\\d+$'
        ORDER BY tablename
        LIMIT #{limit}
      SQL
    end
  end
end
