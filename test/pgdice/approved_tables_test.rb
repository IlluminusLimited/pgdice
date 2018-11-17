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

  def test_comparison
    approved_tables = PgDice::ApprovedTables.new(@table)

    assert_equal approved_tables, PgDice::ApprovedTables.new(@table)
  end

  def test_tables_sort_alphabetically
    approved_tables = PgDice::ApprovedTables.new(@table)
    approved_tables << PgDice::Table.new(table_name: 'aaa', past: 1, future: 0, period: 'day')
    other_tables = PgDice::ApprovedTables.new(PgDice::Table.new(table_name: 'aaa', past: 1, future: 0, period: 'day'))
    other_tables << @table

    assert_equal approved_tables, other_tables
  end

  def test_comparison_of_tables
    approved_tables = PgDice::ApprovedTables.new(@table)
    approved_tables << PgDice::Table.new(table_name: 'aaa', past: 1, future: 0, period: 'day')
    other_tables = PgDice::ApprovedTables.new(PgDice::Table.new(table_name: 'zzz', past: 1, future: 0, period: 'day'))
    other_tables << @table

    refute approved_tables == other_tables
  end
end
