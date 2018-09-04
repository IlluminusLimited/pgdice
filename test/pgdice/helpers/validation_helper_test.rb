# frozen_string_literal: true

require 'test_helper'

class ValidationHelperTest < Minitest::Test
  def test_assert_future_tables_throws
    assert_raises(InsufficientFutureTablesError) do
      PgDice.configuration.validation_helper.assert_future_tables('bob', 30)
    end
  end

  def test_throws_on_unapproved_table
    assert_raises(IllegalTableError) do
      PgDice.configuration.validation_helper.validate_parameters(table_name: 'bob')
    end
  end
end
