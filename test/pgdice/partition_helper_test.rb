# frozen_string_literal: true

require 'test_helper'

class PartitionHelperTest < Minitest::Test
  def teardown
    partition_helper.undo_partitioning(table_name: table_name)
  end

  def test_partition_helper_can_fill
    assert partition_helper.partition_table!(table_name: table_name, fill: true)
  end
end
