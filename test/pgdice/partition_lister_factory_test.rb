# frozen_string_literal: true

require 'test_helper'

class PartitionListerFactoryTest < Minitest::Test
  def test_create_partition_lister
    assert PgDice::PartitionListerFactory.new(PgDice.configuration).call
  end
end
