# frozen_string_literal: true

require 'test_helper'

class QueryExecutorTest < Minitest::Test
  def setup
    @should_raise = true
    @resetter_call_count = 0
    @runner_call_count = 0

    @resetter = resetter
    @runner = runner
  end

  def test_retry_on_pg_error
    PgDice::QueryExecutor.new(logger: logger, connection_supplier: -> { MockPgConnection.new(@runner, @resetter) })
                         .call('blah')

    assert_equal 2, @runner_call_count, 'Runner should be called twice when we catch a PG error'
    assert_equal 1, @resetter_call_count, 'Resetter should be called once when we catch a PG error'
  end

  private

  def resetter
    proc do
      @should_raise = false
      @resetter_call_count += 1
    end
  end

  def runner
    proc do
      @runner_call_count += 1
      raise PG::Error, 'Something bad' if @should_raise
    end
  end
end

class MockPgConnection
  def initialize(runner, resetter)
    @runner = runner
    @resetter = resetter
  end

  def exec(query)
    @runner.call(query)
  end

  def reset
    @resetter.call
  end
end
