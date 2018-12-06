# frozen_string_literal: true

require 'test_helper'

class ValidationTest < Minitest::Test
  def setup
    @validation = PgDice::ValidationFactory.new(PgDice.configuration).call
    @fake_validation = PgDice::ValidationFactory.new(PgDice.configuration,
                                                     period_fetcher_factory: proc { proc { 'day' } },
                                                     partition_lister_factory: proc { proc { generate_tables } },
                                                     current_date_provider: proc { Date.parse('20181021') }).call
  end

  def test_not_partitioned_throws
    assert_raises(PgDice::TableNotPartitionedError) do
      @validation.assert_tables(table_name, past: 30)
    end
  end

  def test_supported_periods
    assert_raises(ArgumentError) do
      @validation.assert_tables(table_name, past: 30, period: :fish)
    end
  end

  def test_nil_is_ignored
    assert_past_tables_error { @fake_validation.assert_tables(table_name, past: 2, future: nil) }
    assert_future_tables_error { @fake_validation.assert_tables(table_name, past: nil, future: 2) }
  end

  def test_only_past_works
    assert_past_tables_error { @fake_validation.assert_tables(table_name, past: 2, future: 2, only: :past) }
    assert @fake_validation.assert_tables(table_name, future: 2, only: :past)
    assert @fake_validation.assert_tables(table_name, only: :past)
  end

  def test_only_future_works
    assert_future_tables_error { @fake_validation.assert_tables(table_name, past: 2, future: 2, only: :future) }
    assert @fake_validation.assert_tables(table_name, past: 2, only: :future)
    assert @fake_validation.assert_tables(table_name, only: :future)
  end

  def test_assert_tables_throws
    PgDice.partition_helper.partition_table(table_name, future: 0, past: 0)

    assert_future_tables_error { @validation.assert_tables(table_name, future: 1) }

    assert_past_tables_error { @validation.assert_tables(table_name, past: 1) }
  ensure
    partition_helper.undo_partitioning(table_name)
  end

  def test_assert_tables_throws_on_unpartitioned
    validation = PgDice::ValidationFactory.new(PgDice.configuration,
                                               partition_lister_factory: proc { proc { generate_tables } },
                                               current_date_provider: proc { Date.parse('20181021') }).call

    assert_raises(PgDice::TableNotPartitionedError) do
      assert validation.assert_tables(table_name, past: 1)
    end
  end

  def test_assert_tables_uses_table_to_assert
    validation = PgDice::ValidationFactory.new(PgDice.configuration,
                                               partition_lister_factory: proc { proc { generate_tables } },
                                               current_date_provider: proc { Date.parse('20181021') }).call
    assert validation.assert_tables(table_name)
  end

  def test_throws_on_unapproved_table
    assert_raises(PgDice::IllegalTableError) { @validation.validate_parameters(table_name: 'bob') }

    # Check errors can be caught at top level
    assert_raises(PgDice::Error) { @validation.validate_parameters(table_name: 'bob') }
  end

  private

  def generate_tables
    %w[comments_20181020 comments_20181021]
  end
end
