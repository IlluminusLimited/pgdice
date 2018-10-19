# frozen_string_literal: true

require 'test_helper'

class PartitionHelperTest < Minitest::Test
  def teardown
    partition_helper.undo_partitioning(table_name)
  end

  def test_partition_helper_can_fill
    assert partition_helper.partition_table!(table_name, fill: true)
  end

  def test_works_year_tables
    table_name = 'posts'
    PgDice.partition_helper.partition_table!(table_name, past: 1, period: :year)
    PgDice.partition_manager.add_new_partitions(table_name, past: 2, future: 2, period: :year)

    PgDice.validation.assert_tables(table_name, future: 2, past: 2)

    assert_future_tables_error { PgDice.validation.assert_tables(table_name, future: 3) }
    assert_past_tables_error { PgDice.validation.assert_tables(table_name, past: 3) }
  ensure
    partition_helper.undo_partitioning('posts')
  end

  def test_works_month_tables
    table_name = 'posts'
    PgDice.partition_helper.partition_table!(table_name, past: 1, period: :month)
    PgDice.partition_manager.add_new_partitions(table_name, future: 2, past: 2, period: :month)

    PgDice.validation.assert_tables(table_name, future: 2, past: 2)

    assert_future_tables_error { PgDice.validation.assert_tables(table_name, future: 3) }
    assert_past_tables_error { PgDice.validation.assert_tables(table_name, past: 3) }
  ensure
    partition_helper.undo_partitioning('posts')
  end

  def test_partition_table_checks_allowed_tables
    assert_raises(PgDice::IllegalTableError) do
      partition_helper.partition_table!('bob', fill: true)
    end
  end

  def test_undo_partitioning_checks_allowed_tables
    assert_raises(PgDice::IllegalTableError) do
      partition_helper.undo_partitioning!('bob')
    end
  end
end
