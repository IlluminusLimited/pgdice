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
      validation_helper.validate_parameters(params)
      pg_slice_manager.add_partitions(params)
    end

    def delete_old_partitions(params = {})
      validation_helper.validate_parameters(params)
      # this wont use pg_slice
    end

    def discover_old_partitions(base_table_name, partitions_older_than_date = Time.now.to_date)
      validation_helper.validate_parameters(table_name: base_table_name)
      partition_tables = database_helper.fetch_partition_tables(base_table_name)

      partition_tables.select do |partition_name|
        partition_created_at_date = Date.parse(partition_name.gsub(/#{base_table_name}_/, ''))
        partition_created_at_date < partitions_older_than_date
      end
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
  end
end
