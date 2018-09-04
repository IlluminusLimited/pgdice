# frozen_string_literal: true

require 'test_helper'

class PartitionManagerTest < Minitest::Test
  def teardown
    partition_helper.undo_partitioning(table_name: table_name)
  end

  def test_future_partitions_can_be_added
    partition_manager = PgDice.partition_manager
    partition_helper.partition_table!(table_name: table_name)

    future_tables = 2

    assert partition_manager.add_new_partitions(table_name: table_name, future: future_tables)

    PgDice::Validation.new(PgDice.configuration).assert_future_tables(table_name, future_tables)
  end

  def test_old_partitions_can_be_listed
    partition_manager = PgDice.partition_manager
    partition_helper.partition_table!(table_name: table_name,
                                      past: 2,
                                      future: 1)

    assert_equal 2, partition_manager.list_old_partitions(table_name: table_name).size
  end

  def test_old_partitions_can_be_dropped
    partition_manager = PgDice.partition_manager
    partition_helper.partition_table!(table_name: table_name, past: 2, future: 1)

    assert_equal 2, partition_manager.drop_old_partitions(table_name: table_name).size
    assert_equal 0, partition_manager.list_old_partitions(table_name: table_name).size
  end

  def test_old_partitions_can_be_limited
    partition_manager = PgDice.partition_manager
    partition_helper.partition_table!(table_name: table_name,
                                      past: 2,
                                      future: 1)

    assert_equal 1, partition_manager.list_old_partitions(table_name: table_name, limit: 1).size
  end
end
