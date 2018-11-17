# frozen_string_literal: true

require 'test_helper'

class TableTest < Minitest::Test
  def setup
    @table = PgDice::Table.new(table_name: 'comments', past: 1, future: 0, period: 'day')
  end

  def test_a_table_can_be_loaded_from_hash
    assert_equal @table, PgDice::Table.from_hash(@table.to_h)
  end

  def test_table_comparison
    same_table = PgDice::Table.new(table_name: 'comments', past: 1, future: 0, period: 'day')
    assert_equal @table, same_table
  end
end
