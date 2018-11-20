# frozen_string_literal: true

require 'test_helper'

class PartitionListerTest < Minitest::Test
  def test_generate_list_sql_works
    dropper = PgDice::PartitionLister.new(query_executor: lambda do |sql|
      assert_equal expected_sql, squish(sql)
      generate_tables
    end)
    assert_equal generate_tables, dropper.call(table_name: 'comments', schema: 'public')
  end

  private

  def expected_sql
    expected = <<~SQL
      SELECT tablename
      FROM pg_tables
      WHERE schemaname = 'public'
        AND tablename ~ '^comments_\\d+$'
      ORDER BY tablename
    SQL
    squish(expected)
  end

  def generate_tables
    %w[comments_20181020 comments_20181021]
  end
end
