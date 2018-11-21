# frozen_string_literal: true

require 'test_helper'

class ValidationFactoryTest < Minitest::Test
  def test_create_validation
    assert PgDice::ValidationFactory.new(PgDice.configuration).call
  end
end
