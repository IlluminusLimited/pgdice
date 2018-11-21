# frozen_string_literal: true

require 'test_helper'

class PartitionDropperTest < Minitest::Test
  def test_generate_drop_sql_works
    expected = "BEGIN;\nDROP TABLE IF EXISTS comments_20181020 CASCADE;\n"\
      "DROP TABLE IF EXISTS comments_20181021 CASCADE;\nCOMMIT;"

    dropper = PgDice::PartitionDropper.new(logger: logger, query_executor: ->(sql) { assert_equal expected, sql })
    assert_equal generate_tables, dropper.call(generate_tables)
  end

  private

  def generate_tables
    %w[comments_20181020 comments_20181021]
  end
end
