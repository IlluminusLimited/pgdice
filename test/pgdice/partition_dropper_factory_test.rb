# frozen_string_literal: true

require 'test_helper'

class PartitionDropperFactoryTest < Minitest::Test
  def test_create_partition_dropper
    assert PgDice::PartitionDropperFactory.new(PgDice.configuration).call
  end
end
