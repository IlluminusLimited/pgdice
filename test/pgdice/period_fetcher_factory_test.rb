# frozen_string_literal: true

require 'test_helper'

class PeriodFetcherFactoryTest < Minitest::Test
  def test_create_period_fetcher
    assert PgDice::PeriodFetcherFactory.new(PgDice.configuration).call
  end
end
