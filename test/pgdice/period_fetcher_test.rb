# frozen_string_literal: true

require 'test_helper'

class PeriodFetcherTest < Minitest::Test
  def test_period_can_be_fetched
    expected = "SELECT obj_description('public.comments'::REGCLASS) AS comment"
    query_executor = lambda do |sql|
      assert_equal expected, sql
      ['period:day']
    end

    period_fetcher = PgDice::PeriodFetcher.new(query_executor: query_executor)
    assert_equal 'day', period_fetcher.call(table_name: 'comments', schema: 'public')
  end
end
