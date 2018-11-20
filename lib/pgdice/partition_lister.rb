# frozen_string_literal: true

# Entry point for PartitionManager
module PgDice
  #  PartitionLister is used to list partitions
  class PartitionLister
    include PgDice::TableFinder

    attr_reader :database_connection

    def initialize(database_connection:)
      @database_connection = database_connection
    end

    def call(all_params)
      sql = build_partition_table_fetch_sql(all_params)
      partition_tables = database_connection.execute(sql).values.flatten
      older_than = all_params[:older_than]
      partition_tables = tables_older_than(partition_tables, older_than) if older_than
      partition_tables
    end

    private

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
