# frozen_string_literal: true

require 'test_helper'

class DatabaseConnectionTest < Minitest::Test
  def test_query_not_executed_when_dry_run_true
    call_count = 0
    do_not_call = proc do
      call_count += 1
    end
    PgDice::DatabaseConnection.new(logger: logger,
                                   query_executor: do_not_call,
                                   dry_run: true).execute('blah')

    assert_equal 0, call_count, 'Call count should never increment when dry_run is true'
  end
end
