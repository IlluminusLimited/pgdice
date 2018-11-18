# frozen_string_literal: true

require 'test_helper'

class ConfigurationFileLoaderTest < Minitest::Test
  def setup
    @config = PgDice.configuration.deep_clone
  end

  def test_throws_if_config_file_nil
    loader = PgDice::ConfigurationFileLoader.new(@config)

    assert_raises(PgDice::InvalidConfigurationError) do
      loader.load_file
    end
  end

  def test_throws_if_config_file_missing
    @config.config_file = 'this_file_is_a_lie'
    loader = PgDice::ConfigurationFileLoader.new(@config)

    assert_raises(PgDice::MissingConfigurationFileError) do
      loader.load_file
    end
  end

  def test_example_config_file_loads
    config = PgDice::Configuration.new
    config.logger = @config.logger
    config.config_file = File.expand_path('../../examples/config.yml', File.dirname(__FILE__))

    loader = PgDice::ConfigurationFileLoader.new(config)

    approved_tables = PgDice::ApprovedTables.new(
      PgDice::Table.new(table_name: 'comments', past: 1, future: 0),
      PgDice::Table.new(table_name: 'posts', past: 10, future: 0)
    )
    loader.load_file
    loaded_config = loader.config

    assert_equal approved_tables, loaded_config.approved_tables
  end

  def test_combine_with_existing_approved_tables
    @config.config_file = File.expand_path('../../examples/config.yml', File.dirname(__FILE__))

    loader = PgDice::ConfigurationFileLoader.new(@config)

    @config.approved_tables = PgDice::ApprovedTables.new(
      PgDice::Table.new(table_name: 'bob', past: 1)
    )
    loader.load_file
    loaded_config = loader.config

    assert_equal 3, loaded_config.approved_tables.size
    assert_equal expected_tables, loaded_config.approved_tables
  end

  private

  def expected_tables
    PgDice::ApprovedTables.new(
      PgDice::Table.new(table_name: 'comments', past: 1, future: 0),
      PgDice::Table.new(table_name: 'posts', past: 10, future: 0),
      PgDice::Table.new(table_name: 'bob', past: 1)
    )
  end
end
