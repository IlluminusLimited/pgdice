# frozen_string_literal: true

require 'test_helper'

class ConfigurationFileLoaderTest < Minitest::Test
  def setup
    @table = PgDice::Table.new(table_name: 'comments', past: 1, future: 0, period: 'day')
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
