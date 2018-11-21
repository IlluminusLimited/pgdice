# frozen_string_literal: true

# Entry point for TableDropperHelper
module PgDice
  # Simple class used to provide a mechanism that users can hook into if they want to override this
  # default behavior for dropping a table.
  class PartitionDropper
    attr_reader :logger, :query_executor

    def initialize(logger:, query_executor:)
      @logger = logger
      @query_executor = query_executor
    end

    def call(old_partitions)
      logger.info { "Partitions to be deleted are: #{old_partitions}" }

      query_executor.call(generate_drop_sql(old_partitions))

      old_partitions
    end

    private

    def generate_drop_sql(old_partitions)
      sql_query = old_partitions.reduce("BEGIN;\n") do |sql, table_name|
        sql + "DROP TABLE IF EXISTS #{table_name} CASCADE;\n"
      end
      sql_query + 'COMMIT;'
    end
  end
end
