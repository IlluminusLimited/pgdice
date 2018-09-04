# frozen_string_literal: true

require 'test_helper'

class DatabaseHelperTest < Minitest::Test
  def test_fetch_partition_tables_works
    PgDice.configuration.preparation_helper.prepare_database!(table_name: 'comments', past: 2)

    tables = PgDice.configuration.database_helper.fetch_partition_tables('comments')
    assert_equal 3, tables.size
  ensure
    PgDice.configuration.preparation_helper.cleanup_database('comments')
  end
end
