# frozen_string_literal: true

require 'test_helper'

class PartitionHelperTest < Minitest::Test
  def teardown
    partition_helper.undo_partitioning(table_name)
  end

  def test_partition_helper_can_fill
    assert partition_helper.partition_table(table_name, fill: true)
  end

  def test_partition_table_checks_allowed_tables
    assert_raises(PgDice::IllegalTableError) do
      partition_helper.partition_table('bob', fill: true)
    end
  end

  def test_undo_partitioning_checks_allowed_tables
    assert_raises(PgDice::IllegalTableError) do
      partition_helper.undo_partitioning!('bob')
    end
  end

  def test_intermediate_tables_can_be_deleted
    # After prepping table an _intermediate table is created
    # if undo_partitioning is called it should drop the itermediate tables
    PgDice.partition_helper.pg_slice_manager.prep(table_name: 'comments',
                                                  past: 1,
                                                  period: 'day',
                                                  column_name: 'created_at')
    assert PgDice.undo_partitioning!('comments')
  end
end
