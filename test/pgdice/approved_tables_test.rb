# frozen_string_literal: true

require 'test_helper'

class ApprovedTablesTest < Minitest::Test
  def setup
    @table = PgDice::Table.new(table_name: 'comments', past: 1, future: 0, period: 'day')
  end

  def test_duplicate_tables_cannot_be_added
    approved_tables = PgDice::ApprovedTables.new(@table)
    approved_tables << @table.dup
    assert_equal 1, approved_tables.size
  end
end
