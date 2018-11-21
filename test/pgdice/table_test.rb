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

  def test_table_full_name
    table = PgDice::Table.new(table_name: 'comments', past: 1, future: 0, period: 'day')

    assert_equal 'public.comments', table.full_name
  end

  def test_table_size
    table = PgDice::Table.new(table_name: 'comments', past: 1, future: 1, period: 'day')

    assert_equal 3, table.size
  end

  def test_table_period
    assert_raises(ArgumentError) do
      PgDice::Table.new(table_name: 'comments', past: 1, future: 1, period: 'uhhh').validate!
    end
  end

  def test_table_type_checks
    assert_raises(ArgumentError) do
      PgDice::Table.new(table_name: 'comments', past: '1', future: '1', period: 'day').validate!
    end
  end
end
