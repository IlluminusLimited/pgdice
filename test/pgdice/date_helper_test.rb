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

  def test_truncate_date_invalid_date
    assert_raises(ArgumentError) do
      truncate_date(nil, 'bad_period')
    end
  end
end
