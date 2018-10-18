# frozen_string_literal: true

require 'test_helper'

class PartitionManagerTest < Minitest::Test
  def setup
    @partition_manager = PgDice.partition_manager
  end

  def teardown
    partition_helper.undo_partitioning(table_name)
  end

  def test_future_partitions_can_be_added
    partition_helper.partition_table!(table_name)

    future_tables = 2

    assert @partition_manager.add_new_partitions(table_name, future: future_tables)

    assert PgDice.validation.assert_tables(table_name: table_name, future: future_tables)
  end

  def test_future_partitions_can_be_dry_run
    configuration = PgDice.configuration.deep_clone
    configuration.dry_run = true
    partition_helper.partition_table!(table_name)

    future_tables = 2

    assert configuration.partition_manager.add_new_partitions(table_name, future: future_tables)

    assert PgDice.validation.assert_tables(table_name: table_name, future: 0, past: 0)
  end

  def test_future_partitions_blows_up_on_unpartitioned_table
    assert_raises(PgDice::PgSliceError) do
      @partition_manager.add_new_partitions(table_name, future: 2)
    end
  end

  def test_old_partitions_can_be_listed
    partition_helper.partition_table!(table_name, past: 2, future: 1)

    assert_equal 2, @partition_manager.list_partitions(table_name, older_than: today).size
    assert PgDice.validation.assert_tables(table_name: table_name, past: 2, future: 1)
  end

  def test_drop_old_partitions_can_be_dry_run
    configuration = PgDice.configuration.deep_clone
    configuration.dry_run = true

    partition_helper.partition_table!(table_name, past: 2)

    assert_equal 0, configuration.partition_manager.drop_old_partitions(table_name,
                                                                        older_than: today).size
    assert PgDice.validation.assert_tables(table_name: table_name, past: 2)
  end

  def test_old_partitions_can_be_dropped
    partition_helper.partition_table!(table_name, past: 2)

    assert_equal 2, @partition_manager.drop_old_partitions(table_name, older_than: today).size
    assert PgDice.validation.assert_tables(table_name: table_name, past: 0)
  end

  def test_drop_old_partitions_uses_batch_size
    batch_size = PgDice.configuration.table_drop_batch_size
    minimum_tables = PgDice.configuration.approved_tables[table_name].past
    partition_helper.partition_table!(table_name, past: (batch_size - minimum_tables + 1))

    assert_equal batch_size, @partition_manager.drop_old_partitions(table_name, older_than: today).size
    assert PgDice.validation.assert_tables(table_name: table_name, past: minimum_tables)
  end

  def test_will_not_drop_more_than_minimum
    PgDice.partition_helper.partition_table!(table_name, past: 3)
    assert_equal 2, PgDice.partition_manager.drop_old_partitions(table_name,
                                                                 older_than: today).size
  end

  def test_add_future_partitions_checks_allowed_tables
    assert_raises(PgDice::IllegalTableError) do
      @partition_manager.add_new_partitions('bob')
    end
  end

  def test_drop_old_partitions_checks_allowed_tables
    assert_raises(PgDice::IllegalTableError) do
      @partition_manager.drop_old_partitions('bob')
    end
  end

  def test_cannot_drop_more_than_minimum_tables
    table_name = 'posts'
    PgDice.partition_helper.partition_table!(table_name, past: 10)
    assert_empty PgDice.partition_manager.list_droppable_tables(table_name,
                                                                older_than: today)
    assert_empty PgDice.partition_manager.drop_old_partitions(table_name,
                                                              older_than: today)
  ensure
    partition_helper.undo_partitioning('posts')
  end

  # Comments table is configured to have a minimum_table_threshold of 1 table
  # Thus there should be no droppable tables if looking older than yesterday.
  def test_list_droppable_tables
    PgDice.partition_helper.partition_table!(table_name, past: 1)
    assert_empty PgDice.partition_manager.list_droppable_tables(table_name, older_than: today)
  end

  private

  def today
    Time.now.utc
  end

  def yesterday
    today - 1 * 24 * 60 * 60
  end
end
