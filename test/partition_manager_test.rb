# frozen_string_literal: true

require 'test_helper'

class PartitionManagerTest < Minitest::Test
  def assert_future_tables_throws
    assert_raises(InsufficientFutureTablesError) do
      PgDice.configuration.partition_manager.assert_future_tables('bob', 30)
    end
  end

  def test_future_partitions_can_be_added
    table_name = 'Comments'
    partition_manager = PgDice.configuration.partition_manager
    partition_manager.prepare_database!(table_name)

    future_tables = 2

    assert partition_manager.add_new_partitions(table_name: table_name, future: future_tables)

    PgDice.configuration.partition_manager.assert_future_tables(table_name, future_tables)
  ensure
    PgDice.configuration.partition_manager.cleanup_database(table_name)
  end
end
