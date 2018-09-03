# frozen_string_literal: true

require 'test_helper'

class PartitionManagerTest < Minitest::Test
  def test_future_partitions_can_be_added
    table_name = 'comments'
    partition_manager = PgDice.configuration.partition_manager
    partition_manager.prepare_database!(table_name: table_name)

    future_tables = 2

    assert partition_manager.add_new_partitions(table_name: table_name, future: future_tables)

    PgDice.configuration.validation_helper.assert_future_tables(table_name, future_tables)
  ensure
    PgDice.configuration.partition_manager.cleanup_database(table_name)
  end
end
