# frozen_string_literal: true

require 'test_helper'

class ValidationTest < Minitest::Test
  def test_assert_future_tables_throws
    assert_raises(PgDice::InsufficientFutureTablesError) do
      PgDice.validation.assert_future_tables(table_name: table_name, future: 30)
    end
  end

  def test_throws_on_unapproved_table
    assert_raises(PgDice::IllegalTableError) do
      PgDice.validation.validate_parameters(table_name: 'bob')
    end

    # Check errors can be caught at top level
    assert_raises(PgDice::Error) do
      PgDice.validation.validate_parameters(table_name: 'bob')
    end
  end

  def test_additional_validators_work
    configuration = PgDice.configuration.deep_clone
    configuration.additional_validators << ->(_params, _logger) { nil }
    assert_raises(PgDice::CustomValidationError) do
      PgDice::Validation.new(configuration).validate_parameters(table_name: table_name)
    end
  end

  def test_configuration_checks
    configuration = PgDice.configuration.deep_clone

    configuration.additional_validators = {}
    configuration.database_connection = nil
    configuration.logger = nil

    validation = PgDice::Validation.new(configuration)
    assert_invalid_config { validation.validate_parameters(table_name: table_name) }
    assert_invalid_config { validation.assert_future_tables(table_name: table_name, future: 1) }
  end
end
