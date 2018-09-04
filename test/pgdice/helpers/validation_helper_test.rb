# frozen_string_literal: true

require 'test_helper'

class ValidationHelperTest < Minitest::Test
  def test_assert_future_tables_throws
    assert_raises(InsufficientFutureTablesError) do
      PgDice.configuration.validation_helper.assert_future_tables('bob', 30)
    end
  end
end
