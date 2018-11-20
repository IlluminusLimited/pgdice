# frozen_string_literal: true

require 'test_helper'

class PartitionListerTest < Minitest::Test
  def test_old_partitions_can_be_listed
    lister = PgDice::PartitionLister.new(query_executor: ->(_sql) { generate_tables })
    response = lister.call(table_name: 'comments', older_than: Date.parse('20181022'))
    assert_equal %w[comments_20181020 comments_20181021], response
  end

  private

  def generate_tables
    %w[comments_20181020 comments_20181021 comments_20181022 comments_20181023 comments_20181024
       comments_20181025 comments_20181026 comments_20181027 comments_20181028 comments_20181029]
  end
end
