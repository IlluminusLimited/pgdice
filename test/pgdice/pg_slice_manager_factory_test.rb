# frozen_string_literal: true

require 'test_helper'

class PgSliceManagerFactoryTest < Minitest::Test
  def test_create_pg_slice_manager
    assert PgDice::PgSliceManagerFactory.new(PgDice.configuration).call
  end
end
