# frozen_string_literal: true

# Entry point for PartitionManager
module PgDice
  #  PartitionLister is used to list partitions
  class PartitionLister
    attr_reader :query_executor

    def initialize(query_executor:)
      @query_executor = query_executor
    end

    def call(all_params)
      sql = build_partition_table_fetch_sql(all_params)
      query_executor.call(sql)
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
        ORDER BY tablename;
      SQL
    end
  end
end
