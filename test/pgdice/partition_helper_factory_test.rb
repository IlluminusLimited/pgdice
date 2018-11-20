# frozen_string_literal: true

require 'test_helper'

class PartitionHelperFactoryTest < Minitest::Test
  def test_create_partition_helper
    assert PgDice::PartitionHelperFactory.new(PgDice.configuration).call
  end
end
