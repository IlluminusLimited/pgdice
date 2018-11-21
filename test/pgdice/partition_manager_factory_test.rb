# frozen_string_literal: true

require 'test_helper'

class PartitionManagerFactoryTest < Minitest::Test
  def test_can_create_partition_manager
    assert PgDice::PartitionManagerFactory.new(PgDice.configuration).call
  end
end
