# frozen_string_literal: true

require 'test_helper'

class ConfigurationFileLoaderTest < Minitest::Test
  def setup
    @config = PgDice.configuration.deep_clone
  end

  def test_throws_if_config_file_nil
    loader = PgDice::ConfigurationFileLoader.new(@config)

    assert_raises(PgDice::InvalidConfigurationError) do
      loader.call
    end
  end

  def test_throws_if_config_file_missing
    @config.config_file = 'this_file_is_a_lie'
    loader = PgDice::ConfigurationFileLoader.new(@config)

    assert_raises(PgDice::MissingConfigurationFileError) do
      loader.call
    end
  end

  def test_example_config_file_loads
    @config.config_file = File.expand_path('../../examples/config.yml', File.dirname(__FILE__))

    loader = PgDice::ConfigurationFileLoader.new(@config)

    config = PgDice::Configuration.new
    config.approved_tables = PgDice::ApprovedTables.new(
      PgDice::Table.new(table_name: 'comments', past: 1),
      PgDice::Table.new(table_name: 'posts', past: 10)
    )
    loaded_config = loader.call

    assert_equal config.approved_tables, loaded_config.approved_tables
  end
end
