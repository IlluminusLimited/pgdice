# frozen_string_literal: true

require 'test_helper'

class TableTest < Minitest::Test
  def setup
    @table = PgDice::Table.new(table_base_name: 'comments', past: 1, future: 0, period: 'day')
  end

  def test_a_table_can_be_loaded_from_json
    assert_equal @table, PgDice::Table.from_json(@table.to_json)
  end

  def test_a_table_can_be_loaded_from_hash
    assert_equal @table, PgDice::Table.from_hash(@table.to_h)
  end
end
