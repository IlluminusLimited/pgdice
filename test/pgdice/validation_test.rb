# frozen_string_literal: true

require 'test_helper'

class ValidationTest < Minitest::Test
  def test_assert_tables_throws
    assert_raises(PgDice::InsufficientFutureTablesError) do
      PgDice.validation.assert_tables(table_name: table_name, future: 30)
    end

    assert_raises(PgDice::InsufficientPastTablesError) do
      PgDice.validation.assert_tables(table_name: table_name, past: 30)
    end
  end

  def test_suppoerted_periods
    assert_raises(ArgumentError) do
      PgDice.validation.assert_tables(table_name: table_name, past: 30, period: :fish)
    end
  end

  # def test_assert_tables_works_with_year_tables
  #   table_name = 'posts'
  #   PgDice.partition_helper.partition_table!(table_name: table_name, period: :year)
  #   assert_raises(PgDice::InsufficientFutureTablesError) do
  #     PgDice.validation.assert_tables(table_name: table_name, future: 30)
  #   end
  #
  #   assert_raises(PgDice::InsufficientPastTablesError) do
  #     PgDice.validation.assert_tables(table_name: table_name, past: 30)
  #   end
  # end

  def test_assert_tables_requires_past_or_future
    assert_raises(ArgumentError) do
      PgDice.validation.assert_tables(table_name: table_name)
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

  def test_failed_custom_validator_throws
    configuration = PgDice.configuration.deep_clone
    configuration.additional_validators << ->(_params, _logger) { nil }
    assert_raises(PgDice::CustomValidationError) do
      PgDice::Validation.new(configuration).validate_parameters(table_name: table_name)
    end
  end

  def test_good_custom_validator_works
    configuration = PgDice.configuration.deep_clone
    configuration.additional_validators << ->(_params, _logger) { true }
    assert PgDice::Validation.new(configuration).validate_parameters(table_name: table_name)
  end
end
