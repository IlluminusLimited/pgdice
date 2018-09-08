# frozen_string_literal: true

require 'test_helper'

class PartitionManagerTest < Minitest::Test
  def setup
    @partition_manager = PgDice.partition_manager
  end

  def teardown
    partition_helper.undo_partitioning(table_name: table_name)
  end

  def test_future_partitions_can_be_added
    partition_helper.partition_table!(table_name: table_name)

    future_tables = 2

    assert @partition_manager.add_new_partitions(table_name: table_name, future: future_tables)

    assert PgDice.validation.assert_future_tables(table_name: table_name, future: future_tables)
  end

  def test_future_partitions_can_be_dry_run
    configuration = PgDice.configuration.deep_clone
    configuration.dry_run = true
    partition_helper.partition_table!(table_name: table_name)

    future_tables = 2

    assert configuration.partition_manager.add_new_partitions(table_name: table_name, future: future_tables)

    assert PgDice.validation.assert_future_tables(table_name: table_name, future: 0)
  end

  def test_future_partitions_blows_up_on_unpartitioned_table
    assert_raises(PgDice::PgSliceError) do
      @partition_manager.add_new_partitions(table_name: table_name, future: 2)
    end
  end

  def test_old_partitions_can_be_listed
    partition_helper.partition_table!(table_name: table_name, past: 2, future: 1)

    assert_equal 2, @partition_manager.list_old_partitions(table_name: table_name).size
  end

  def test_drop_old_partitions_can_be_dry_run
    configuration = PgDice.configuration.deep_clone
    configuration.dry_run = true

    partition_helper.partition_table!(table_name: table_name, past: 2)

    assert_equal 0, configuration.partition_manager.drop_old_partitions(table_name: table_name).size
    assert_equal 2, @partition_manager.list_old_partitions(table_name: table_name).size
  end

  def test_old_partitions_can_be_dropped
    partition_helper.partition_table!(table_name: table_name, past: 2)

    assert_equal 2, @partition_manager.drop_old_partitions(table_name: table_name).size
    assert_equal 0, @partition_manager.list_old_partitions(table_name: table_name).size
  end

  def test_old_partitions_can_be_dropped_with_limit
    partition_helper.partition_table!(table_name: table_name, past: 2)

    old_partition = @partition_manager.list_old_partitions(table_name: table_name, limit: 1).first

    assert_equal 1, @partition_manager.drop_old_partitions(table_name: table_name, limit: 1).size
    refute_equal old_partition, @partition_manager.list_old_partitions(table_name: table_name, limit: 1).first
  end

  def test_drop_old_partitions_uses_batch_size
    batch_size = PgDice.configuration.table_drop_batch_size
    partition_helper.partition_table!(table_name: table_name, past: batch_size + 1)

    assert_equal batch_size, @partition_manager.drop_old_partitions(table_name: table_name).size
    assert_equal 1, @partition_manager.list_old_partitions(table_name: table_name).size
  end
end
