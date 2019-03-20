# frozen_string_literal: true

require 'test_helper'

class TableFinderTest < Minitest::Test
  include PgDice::DateHelper

  def test_safe_date_builder_invalid_date
    assert_raises(ArgumentError) do
      safe_date_builder('comments_201')
    end
  end

  def test_safe_date_builder_days
    table_name = 'comments_20180322'
    assert_equal Date.parse('20180322'), safe_date_builder(table_name)
  end

  def test_safe_date_builder_months
    table_name = 'comments_201803'
    assert_equal Date.parse('20180301'), safe_date_builder(table_name)
  end

  def test_safe_date_builder_years
    table_name = 'comments_2018'
    assert_equal Date.parse('20180101'), safe_date_builder(table_name)
  end

  def test_truncate_date_day
    assert_equal Date.parse('20180322'), truncate_date(Date.parse('20180322'), 'day')
  end

  def test_truncate_date_month
    assert_equal Date.parse('20180301'), truncate_date(Date.parse('20180322'), 'month')
  end

  def test_truncate_date_year
    assert_equal Date.parse('20180101'), truncate_date(Date.parse('20180322'), 'year')
  end

  def test_truncate_date_invalid_date
    assert_raises(ArgumentError) do
      truncate_date(nil, 'bad_period')
    end
  end
end
