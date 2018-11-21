# frozen_string_literal: true

require 'test_helper'

class ValidationTest < Minitest::Test
  def setup
    @validation = PgDice::ValidationFactory.new(PgDice.configuration).call
  end

  def test_not_partitioned_throws
    assert_raises(PgDice::TableNotPartitionedError) do
      @validation.assert_tables(table_name, past: 30)
    end
  end

  def test_supported_periods
    assert_raises(ArgumentError) do
      @validation.assert_tables(table_name, past: 30, period: :fish)
    end
  end

  def test_assert_tables_throws
    PgDice.partition_helper.partition_table(table_name, future: 0, past: 0)

    assert_future_tables_error { @validation.assert_tables(table_name, future: 1) }

    assert_past_tables_error { @validation.assert_tables(table_name, past: 1) }
  ensure
    partition_helper.undo_partitioning(table_name)
  end

  def test_assert_tables_works_with_year_tables
    table_name = 'posts'
    PgDice.partition_helper.partition_table(table_name, future: 1, past: 0, period: 'year')

    @validation.assert_tables(table_name, future: 1, past: 0)

    assert_future_tables_error { @validation.assert_tables(table_name, future: 2) }

    assert_past_tables_error { @validation.assert_tables(table_name, past: 1) }
  ensure
    partition_helper.undo_partitioning('posts')
  end

  def test_assert_tables_requires_past_or_future
    assert_raises(ArgumentError) do
      @validation.assert_tables(table_name, {})
    end
  end

  def test_throws_on_unapproved_table
    assert_raises(PgDice::IllegalTableError) { @validation.validate_parameters(table_name: 'bob') }

    # Check errors can be caught at top level
    assert_raises(PgDice::Error) { @validation.validate_parameters(table_name: 'bob') }
  end
end
