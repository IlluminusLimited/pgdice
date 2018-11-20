# frozen_string_literal: true

module PgDice
  # Module which is a collection of methods used by PartitionManager to find and list tables
  module TableFinder
    def find_droppable_partitions(all_tables, older_than, minimum_tables)
      tables_older_than = tables_older_than(all_tables, older_than)
      tables_to_grab = tables_to_grab(tables_older_than.size, minimum_tables)
      tables_older_than.first(tables_to_grab)
    end

    def tables_to_grab(eligible_tables, minimum_tables)
      tables_to_grab = eligible_tables - minimum_tables
      tables_to_grab.positive? ? tables_to_grab : 0
    end

    def batched_tables(tables, batch_size)
      tables.first(batch_size)
    end

    def tables_older_than(tables, older_than)
      table_tester(tables, ->(partition_created_at_time) { partition_created_at_time < older_than.to_date })
    end

    def tables_newer_than(tables, newer_than)
      table_tester(tables, ->(partition_created_at_time) { partition_created_at_time > newer_than.to_date })
    end

    def table_tester(tables, predicate)
      tables.select do |partition_name|
        partition_created_at_time = Date.parse(partition_name)
        predicate.call(partition_created_at_time)
      end
    end
  end
end
