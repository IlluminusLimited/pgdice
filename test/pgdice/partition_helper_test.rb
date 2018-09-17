# frozen_string_literal: true

require 'test_helper'

class PartitionHelperTest < Minitest::Test
  def teardown
    partition_helper.undo_partitioning(table_name: table_name)
  end

  def test_partition_helper_can_fill
    assert partition_helper.partition_table!(table_name: table_name, fill: true)
  end

  def test_works_year_tables
    table_name = 'posts'
    PgDice.partition_helper.partition_table!(table_name: table_name, period: :year)
    PgDice.partition_manager.add_new_partitions(table_name: table_name, future: 2, past: 2)

    assert_future_tables_error { PgDice.validation.assert_tables(table_name: table_name, future: 2) }
    assert_past_tables_error { PgDice.validation.assert_tables(table_name: table_name, past: 2) }
  ensure
    partition_helper.undo_partitioning(table_name: 'posts')
  end

  def test_works_month_tables
    table_name = 'posts'
    PgDice.partition_helper.partition_table!(table_name: table_name, period: :month)
    PgDice.partition_manager.add_new_partitions(table_name: table_name, future: 2, past: 2)

    assert_future_tables_error { PgDice.validation.assert_tables(table_name: table_name, future: 2) }
    assert_past_tables_error { PgDice.validation.assert_tables(table_name: table_name, past: 2) }
  ensure
    partition_helper.undo_partitioning(table_name: 'posts')
  end

  def test_partition_table_checks_allowed_tables
    assert_raises(PgDice::IllegalTableError) do
      partition_helper.partition_table!(table_name: 'bob', fill: true)
    end
  end

  def test_undo_partitioning_checks_allowed_tables
    assert_raises(PgDice::IllegalTableError) do
      partition_helper.undo_partitioning!(table_name: 'bob')
    end
  end

  private

  def assert_future_tables_error(&block)
    assert_raises(PgDice::InsufficientFutureTablesError) { block.yield }
  end

  def assert_past_tables_error(&block)
    assert_raises(PgDice::InsufficientPastTablesError) { block.yield }
  end
end
