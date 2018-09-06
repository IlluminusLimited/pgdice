# frozen_string_literal: true

require 'test_helper'

class ValidationTest < Minitest::Test
  def test_assert_future_tables_throws
    assert_raises(PgDice::InsufficientFutureTablesError) do
      PgDice::Validation.new(PgDice.configuration).assert_future_tables('bob', 30)
    end
  end

  def test_throws_on_unapproved_table
    assert_raises(PgDice::IllegalTableError) do
      PgDice::Validation.new(PgDice.configuration).validate_parameters(table_name: 'bob')
    end

    # Check errors can be caught at top level
    assert_raises(PgDice::Error) do
      PgDice::Validation.new(PgDice.configuration).validate_parameters(table_name: 'bob')
    end
  end

  def test_additional_validators_work
    configuration = PgDice.configuration.dup
    configuration.additional_validators << ->(_params, _logger) { nil }
    assert_raises(PgDice::CustomValidationError) do
      PgDice::Validation.new(configuration).validate_parameters(table_name: 'comments')
    end
  end
end
