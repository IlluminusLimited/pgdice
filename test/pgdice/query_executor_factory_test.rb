# frozen_string_literal: true

require 'test_helper'

class QueryExecutorFactoryTest < Minitest::Test
  def test_can_generate_query_executor
    assert PgDice::QueryExecutorFactory.new(PgDice.configuration).call
  end
end
