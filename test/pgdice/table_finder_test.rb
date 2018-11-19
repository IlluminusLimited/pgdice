# frozen_string_literal: true

require 'test_helper'

class TableFinderTest < Minitest::Test
  def test_find_droppable_partitions
    results = PgDice::TableFinder.new.find_droppable_partitions(generate_tables, Date.parse('20181022'), 1)
    assert_equal ["comments_20181020"], results
  end

  def test_tables_to_grab_returns_0_on_negative_math
    results = PgDice::TableFinder.new.tables_to_grab(1, 2)
    assert_equal 0, results
  end

  def test_find_droppable_tables_returns_empty_list_when_minimum_not_met
    results = PgDice::TableFinder.new.find_droppable_partitions(generate_tables, Date.parse('20181022'), 2)
    assert_empty results
  end

  def test_tables_older_than
    results = PgDice::TableFinder.new.tables_older_than(generate_tables, Date.parse('20181022'))
    assert_equal %w(comments_20181020 comments_20181021), results
  end

  def test_batched_tables
    results = PgDice::TableFinder.new.batched_tables(generate_tables, 3)
    assert_equal %w(comments_20181020 comments_20181021 comments_20181022), results
  end

  def test_batched_tables_large_batch_size
    results = PgDice::TableFinder.new.batched_tables(generate_tables, 10)
    assert_equal generate_tables, results
  end


  private

  def generate_tables
    %w(comments_20181020 comments_20181021 comments_20181022 comments_20181023 comments_20181024 comments_20181025 comments_20181026)
  end
end
