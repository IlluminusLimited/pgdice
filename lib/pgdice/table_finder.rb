# frozen_string_literal: true

module PgDice
  # Module which is a collection of methods used by PartitionManager to find and list tables
  module TableFinder
    def populate_variables(table_name, params)
      table = approved_tables.fetch(table_name)
      all_params = table.smash(params)
      batch_size = all_params.fetch(:table_drop_batch_size, table_drop_batch_size)
      older_than = all_params.fetch(:older_than).to_date
      minimum_tables = all_params[:past]
      current_date = @current_date_provider.call
      [table, batch_size, older_than, minimum_tables, current_date]
    end

    def process_droppable_tables(older_than, current_date, batch_size, minimum_tables, table)
      eligible_partitions = list_partitions(table.name, older_than: current_date)
      selected_partitions = filter_partitions(eligible_partitions, table.name, older_than)
      tables_to_drop = calculate_tables_to_drop(batch_size, minimum_tables, eligible_partitions, selected_partitions)
      remaining_partitions = eligible_partitions.size - tables_to_drop
      select_tables_to_drop(remaining_partitions, minimum_tables, tables_to_drop, table, selected_partitions)
    end

    def select_tables_to_drop(remaining_partitions, minimum_tables, tables_to_drop, table, selected_partitions)
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

    def handle_returned_partitions(table, partition_tables, older_than)
      logger.debug { "Table: #{table} has partition_tables: #{partition_tables}" }
      if older_than
        partition_tables = filter_partitions(partition_tables, table.name, older_than)
        logger.debug do
          "Filtered partitions for table: #{table.full_name} and older_than: #{older_than} are: #{partition_tables}"
        end
      end
      partition_tables
    end

    def handle_partition_dropping(old_partitions)
      logger.info { "Partitions to be deleted are: #{old_partitions}" }

      old_partitions.each do |old_partition|
        @configuration.table_dropper.call(old_partition, logger)
      end
      old_partitions
    end

    def calculate_tables_to_drop(batch_size, minimum_tables, eligible_partitions, selected_partitions)
      expected_tables_to_drop = batch_size > selected_partitions.size ? selected_partitions.size : batch_size
      remaining_partitions = eligible_partitions.size - expected_tables_to_drop

      tables_to_drop = if remaining_partitions < minimum_tables
                         expected_tables_to_drop - minimum_tables
                       else
                         expected_tables_to_drop
                       end
      tables_to_drop.abs
    end

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
