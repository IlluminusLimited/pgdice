# frozen_string_literal: true

require 'test_helper'

class DatabaseHelperTest < Minitest::Test
  def teardown
    preparation_helper.cleanup_database(table_name)
  end

  def test_fetch_partition_tables_works
    preparation_helper.prepare_database!(table_name: 'comments', past: 2)

    tables = PgDice::DatabaseHelper.new(PgDice.configuration).fetch_partition_tables('comments')
    assert_equal 3, tables.size
  end
end
