# frozen_string_literal: true

require 'test_helper'

class DatabaseConnectionFactoryTest < Minitest::Test
  def test_create_database_connection
    assert PgDice::DatabaseConnectionFactory.new(PgDice.configuration).call
  end
end
