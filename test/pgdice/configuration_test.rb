# frozen_string_literal: true

require 'test_helper'

class ConfigurationTest < Minitest::Test
  def setup
    @configuration = PgDice.configuration.deep_clone
  end

  def test_no_config_throws
    configuration = PgDice.configuration
    PgDice.configuration = nil
    assert_not_configured { PgDice.partition_manager.add_new_partitions(table_name: 'bob') }
    assert_not_configured { PgDice.partition_helper.partition_table!(table_name: 'bob') }
    assert_not_configured { PgDice.validation.validate_parameters(table_name: 'bob') }
  ensure
    PgDice.configuration = configuration
  end

  def test_nil_logger_throws
    @configuration.logger = nil
    assert_invalid_config { @configuration.logger }
  end

  def test_nil_database_url_throws
    @configuration.database_url = nil
    assert_invalid_config { @configuration.database_url }
  end

  def test_nil_database_connection_throws
    @configuration.database_connection = nil
    assert_invalid_config { @configuration.database_connection }
  end

  def test_nil_additional_validators_throws
    @configuration.additional_validators = nil
    assert_invalid_config { @configuration.additional_validators }
  end

  def test_nil_approved_tables_throws
    @configuration.approved_tables = nil
    assert_invalid_config { @configuration.approved_tables }
  end

  def test_nil_older_than_throws
    @configuration.older_than = nil
    assert_invalid_config { @configuration.older_than }
  end

  def test_nil_dry_run_throws
    @configuration.dry_run = nil
    assert_invalid_config { @configuration.dry_run }
  end

  private

  def assert_not_configured(&block)
    assert_raises(PgDice::NotConfiguredError) { block.yield }
  end
end
