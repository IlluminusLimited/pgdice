# frozen_string_literal: true

require 'test_helper'

class ConfigurationTest < Minitest::Test
  def test_database_url_can_be_set
    PgDice.configure do |config|
      config.database_url = 'this_is_a_url'
    end
    assert_equal 'this_is_a_url', PgDice.configuration.database_url
  end
end
