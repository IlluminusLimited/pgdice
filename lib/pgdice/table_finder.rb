# frozen_string_literal: true

module PgDice
  # Module which is a collection of methods used by PartitionManager to find and list tables
  class TableFinder
    include PgDice::Loggable

    def initialize(configuration = PgDice::Configuration.new)
      @configuration = configuration
    end


    def find_droppable_partitions(all_tables, older_than, minimum_tables)
      tables_older_than = tables_older_than(all_tables, older_than)
      tables_to_grab = tables_to_grab(tables_older_than.size, minimum_tables)
      tables_older_than.first(tables_to_grab)
    end

    def tables_to_grab(eligible_tables, minimum_tables)
      tables_to_grab = eligible_tables - minimum_tables
      tables_to_grab.positive? ? tables_to_grab : 0
    end

    def tables_older_than(tables, older_than)
      tables.select do |partition_name|
        partition_created_at_time = Date.parse(partition_name)
        partition_created_at_time < older_than.to_date
      end
    end

    def batched_tables(tables, batch_size)
      tables.first(batch_size)
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
