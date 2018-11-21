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
    assert_not_configured { PgDice.partition_helper.partition_table(table_name: 'bob') }
    assert_not_configured { PgDice.validation.validate_parameters(table_name: 'bob') }
  ensure
    PgDice.configuration = configuration
  end

  def test_nil_logger_factory_throws
    @configuration.logger_factory = nil
    assert_invalid_config { @configuration.logger_factory }
  end

  def test_nil_database_url_throws
    @configuration.database_url = nil
    assert_invalid_config { @configuration.database_url }
  end

  def test_nil_approved_tables_throws_if_config_file_unset
    @configuration.approved_tables = nil
    @configuration.config_file = nil
    assert_invalid_config { @configuration.approved_tables }
  end

  def test_nil_dry_run_throws
    @configuration.dry_run = nil
    assert_invalid_config { @configuration.dry_run }
  end

  def test_invalid_batch_size_throws
    @configuration.batch_size = -1
    assert_invalid_config { @configuration.batch_size }
  end

  def test_invalid_pg_connection_throws
    @configuration.pg_connection = -1
    assert_invalid_config { @configuration.pg_connection }
  end

  def test_config_file_loader_is_called_if_approved_tables_is_nil
    @configuration.config_file = nil
    @configuration.approved_tables = nil
    assert_raises(PgDice::InvalidConfigurationError) do
      @configuration.approved_tables
    end
  end

  def test_config_file_loader_is_called
    table = { 'approved_tables' => [] }
    @configuration.approved_tables = []
    @configuration.config_file_loader = PgDice::ConfigurationFileLoader.new(@configuration,
                                                                            file_validator: proc { true },
                                                                            config_loader: proc { table })

    assert @configuration.approved_tables
  end

  def test_blow_up_if_approved_tables_are_not_set_up
    @configuration.approved_tables = []
    @configuration.config_file = 'git_rekt'
    assert_raises(PgDice::MissingConfigurationFileError) do
      @configuration.validate!
    end
  end

  def test_nil_logger_calls_logger_factory
    call_count = 0
    dummy_factory = proc do
      call_count += 1
    end

    @configuration.logger = nil
    @configuration.logger_factory = dummy_factory
    @configuration.logger
    assert_equal 1, call_count, 'Logger factory should be called to initialize logger'
  end

  private

  def assert_not_configured(&block)
    assert_raises(PgDice::NotConfiguredError) { block.yield }
  end
end
