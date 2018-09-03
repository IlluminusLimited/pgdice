# frozen_string_literal: true

class ValidationHelperTest < Minitest::Test
  def assert_future_tables_throws
    assert_raises(InsufficientFutureTablesError) do
      PgDice.validation_helper.assert_future_tables('bob', 30)
    end
  end
end
