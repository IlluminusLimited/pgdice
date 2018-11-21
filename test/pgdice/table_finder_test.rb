# frozen_string_literal: true

require 'test_helper'

class TableFinderTest < Minitest::Test
  include PgDice::TableFinder

  def test_find_droppable_partitions
    results = find_droppable_partitions(generate_tables, Date.parse('20181022'), 1, 'day')
    assert_equal ['comments_20181020'], results
  end

  def test_find_droppable_tables_returns_empty_list_when_minimum_not_met
    results = find_droppable_partitions(generate_tables, Date.parse('20181022'), 2, 'day')
    assert_empty results
  end

  def test_tables_older_than
    results = tables_older_than(generate_tables, Date.parse('20181022'), 'day')
    assert_equal %w[comments_20181020 comments_20181021], results
  end

  def test_tables_newer_than
    results = tables_newer_than(generate_tables, Date.parse('20181024'), 'day')
    assert_equal %w[comments_20181025 comments_20181026], results
  end

  def test_batched_tables
    results = batched_tables(generate_tables, 3)
    assert_equal %w[comments_20181020 comments_20181021 comments_20181022], results
  end

  def test_batched_tables_large_batch_size
    results = batched_tables(generate_tables, 10)
    assert_equal generate_tables, results
  end

  def test_safe_date_builder_invalid_date
    assert_raises(ArgumentError) do
      safe_date_builder('comments_201')
    end
  end

  def test_safe_date_builder_days
    table_name = 'comments_20181022'
    assert_equal Date.parse('20181022'), safe_date_builder(table_name)
  end

  def test_safe_date_builder_months
    table_name = 'comments_201810'
    assert_equal Date.parse('20181001'), safe_date_builder(table_name)
  end

  def test_safe_date_builder_years
    table_name = 'comments_2018'
    assert_equal Date.parse('20180101'), safe_date_builder(table_name)
  end

  def test_truncate_date_day
    assert_equal Date.parse('20181022'), truncate_date(Date.parse('20181022'), 'day')
  end

  def test_truncate_date_month
    assert_equal Date.parse('20181001'), truncate_date(Date.parse('20181022'), 'month')
  end

  def test_truncate_date_year
    assert_equal Date.parse('20180101'), truncate_date(Date.parse('20181022'), 'year')
  end

  def test_tables_to_grab_returns_0_on_negative_math
    results = tables_to_grab(1, 2)
    assert_equal 0, results
  end

  private

  def generate_tables
    %w[comments_20181020 comments_20181021 comments_20181022 comments_20181023 comments_20181024
       comments_20181025 comments_20181026]
  end
end
