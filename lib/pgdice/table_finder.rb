# frozen_string_literal: true

module PgDice
  # Module which is a collection of methods used by PartitionManager to find and list tables
  module TableFinder
    include PgDice::DateHelper

    def find_droppable_partitions(all_tables, older_than, minimum_tables, period)
      tables_older_than = tables_older_than(all_tables, older_than, period)
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

    def tables_older_than(tables, older_than, period)
      table_tester(tables, lambda do |partition_created_at_time|
        partition_created_at_time < truncate_date(older_than.to_date, period)
      end)
    end

    def tables_newer_than(tables, newer_than, period)
      table_tester(tables, lambda do |partition_created_at_time|
        partition_created_at_time > truncate_date(newer_than.to_date, period)
      end)
    end

    def table_tester(tables, predicate)
      tables.select do |partition_name|
        predicate.call(safe_date_builder(partition_name))
      end
    end
  end
end
