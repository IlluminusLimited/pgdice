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

    assert_raises(PgDice::InsufficientFutureTablesError) do
      PgDice.validation.assert_tables(table_name: table_name, future: 2)
    end

    assert_raises(PgDice::InsufficientPastTablesError) do
      PgDice.validation.assert_tables(table_name: table_name, past: 2)
    end
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
end
