# frozen_string_literal: true

require 'test_helper'

class PartitionManagerTest < Minitest::Test
  def test_future_partitions_can_be_added
    table_name = 'comments'
    partition_manager = PgDice.configuration.partition_manager
    PgDice.configuration.preparation_helper.prepare_database!(table_name: table_name)

    future_tables = 2

    assert partition_manager.add_new_partitions(table_name: table_name, future: future_tables)

    PgDice.configuration.validation_helper.assert_future_tables(table_name, future_tables)
  ensure
    PgDice.configuration.preparation_helper.cleanup_database(table_name)
  end

  def test_old_partitions_can_be_listed
    table_name = 'comments'
    partition_manager = PgDice.configuration.partition_manager
    PgDice.configuration.preparation_helper.prepare_database!(table_name: table_name,
                                                              past: 2,
                                                              future: 1)

    assert_equal 2, partition_manager.list_old_partitions(table_name: table_name).size
  ensure
    PgDice.configuration.preparation_helper.cleanup_database(table_name)
  end

  def test_old_partitions_can_be_dropped
    table_name = 'comments'
    partition_manager = PgDice.configuration.partition_manager
    PgDice.configuration.preparation_helper.prepare_database!(table_name: table_name,
                                                              past: 2,
                                                              future: 1)

    assert_equal 2, partition_manager.drop_old_partitions(table_name: table_name).size
    assert_equal 0, partition_manager.list_old_partitions(table_name: table_name).size
  ensure
    PgDice.configuration.preparation_helper.cleanup_database(table_name)
  end
end
