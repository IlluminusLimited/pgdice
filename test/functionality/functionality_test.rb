# frozen_string_literal: true

require 'test_helper'

class FunctionalityTest < Minitest::Test
  def setup
    @partition_manager = PgDice.partition_manager
  end

  def teardown
    partition_helper.undo_partitioning(table_name)
  end

  def test_future_partitions_blows_up_on_unpartitioned_table
    assert_raises(PgDice::PgSliceError) do
      @partition_manager.add_new_partitions(table_name, future: 2)
    end
  end

  def test_can_be_dry_run
    configuration = PgDice.configuration.deep_clone
    configuration.dry_run = true
    partition_helper.partition_table(table_name, past: 2)

    assert_dry_future(configuration)
    assert_dry_past(configuration)
  end

  def test_drop_old_partitions_uses_batch_size
    batch_size, minimum_tables = batch_size_and_minimum_tables
    partition_helper.partition_table(table_name, past: (batch_size + minimum_tables))

    assert_equal batch_size, @partition_manager.drop_old_partitions(table_name).size
    assert PgDice.validation.assert_tables(table_name, past: minimum_tables)
  end

  def test_will_not_drop_more_than_minimum
    PgDice.partition_helper.partition_table(table_name, past: 3)
    assert_equal 2, PgDice.partition_manager.drop_old_partitions(table_name).size
    assert PgDice.validation.assert_tables(table_name, past: 1)
  end

  def test_works_year_tables
    stupid_codeclimate('posts', :year)
  ensure
    partition_helper.undo_partitioning('posts')
  end

  def test_works_month_tables
    stupid_codeclimate('posts', :month)
  ensure
    partition_helper.undo_partitioning('posts')
  end

  private

  def assert_dry_future(configuration)
    configuration.partition_manager.add_new_partitions(table_name, future: 4)
    assert PgDice.validation.assert_tables(table_name, future: 0, past: 2)
  end

  def assert_dry_past(configuration)
    assert_equal 0, configuration.partition_manager.drop_old_partitions(table_name).size
    assert PgDice.validation.assert_tables(table_name, future: 0, past: 2)
  end

  def batch_size_and_minimum_tables
    batch_size = PgDice.configuration.batch_size
    minimum_tables = PgDice.configuration.approved_tables[table_name].past
    [batch_size, minimum_tables]
  end

  def stupid_codeclimate(table_name, period)
    PgDice.partition_helper.partition_table(table_name, past: 2, future: 2, period: period)
    PgDice.validation.assert_tables(table_name, future: 2, past: 2)
    assert_future_tables_error { PgDice.validation.assert_tables(table_name, future: 3) }
    assert_past_tables_error { PgDice.validation.assert_tables(table_name, past: 3) }
  end
end
