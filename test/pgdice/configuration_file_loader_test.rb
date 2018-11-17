# frozen_string_literal: true

require 'test_helper'

class ConfigurationFileLoaderTest < Minitest::Test
  def test_throws_if_config_file_nil
    loader = PgDice::ConfigurationFileLoader.new

    assert_raises(PgDice::InvalidConfigurationError) do
      loader.call
    end
  end

  def test_throws_if_config_file_missing
    loader = PgDice::ConfigurationFileLoader.new(config_file: 'this_file_is_a_lie')

    assert_raises(PgDice::MissingConfigurationFileError) do
      loader.call
    end
  end

  def test_example_config_file_loads
    loader = PgDice::ConfigurationFileLoader.new(config_file:
                                                     File.expand_path('../../examples/config.yml',
                                                                      File.dirname(__FILE__)))
    config = PgDice::Configuration.new
    config.approved_tables = PgDice::ApprovedTables.new(
      PgDice::Table.new(table_name: 'comments', past: 1),
      PgDice::Table.new(table_name: 'posts', past: 10)
    )
    loaded_config = loader.call

    assert_equal config.approved_tables, loaded_config.approved_tables
  end
end
