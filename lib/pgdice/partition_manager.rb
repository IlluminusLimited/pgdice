# frozen_string_literal: true

require 'pgdice/helpers/validation_helper'

# Entry point for PartitionManager
module PgDice
  #  PartitionManager is a class used to fulfill high-level tasks for partitioning
  class PartitionManager
    def initialize(configuration = Configuration.new)
      @configuration = configuration
    end

    def add_new_partitions(params = {})
      logger.info {"add_new_partitions has been called with params: #{params}"}

      validation_helper.validate_parameters(params)
      pg_slice_manager.add_partitions(params)
    end

    def drop_old_partitions(params = {})
      logger.info { "drop_old_partitions has been called with params: #{params}" }

      validation_helper.validate_parameters(params)
      old_partitions = list_old_partitions(params)
      logger.warn { "Partitions to be deleted are: #{old_partitions}" }

      old_partitions.each do |old_partition|
        @configuration.table_dropper_helper.call(old_partition)
      end
      old_partitions
    end

    def list_old_partitions(params = {})
      partitions_older_than_utc_date = params[:partitions_older_than_utc_date] ||= Time.now.utc.to_date
      logger.info {"Listing old partitions with params: #{params}"}

      validation_helper.validate_parameters(params)

      partition_tables = database_helper.fetch_partition_tables(params[:table_name])
      logger.debug("Filtering out partitions newer than #{partitions_older_than_utc_date}")

      filter_partitions(partition_tables, params[:table_name], partitions_older_than_utc_date)
    end

    private

    def logger
      @configuration.logger
    end

    def pg_slice_manager
      @configuration.pg_slice_manager
    end

    def validation_helper
      @configuration.validation_helper
    end

    def database_helper
      @configuration.database_helper
    end

    def filter_partitions(partition_tables, base_table_name, partitions_older_than_date)
      partition_tables.select do |partition_name|
        partition_created_at_date = Date.parse(partition_name.gsub(/#{base_table_name}_/, ''))
        partition_created_at_date < partitions_older_than_date
      end
    end
  end
end
