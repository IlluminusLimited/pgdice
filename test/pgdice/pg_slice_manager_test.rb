# frozen_string_literal: true

require 'test_helper'

class PgSliceManagerTest < Minitest::Test
  def test_dry_run_add_partitions
    call_count = 0
    executor = proc do |command|
      call_count += 1
      assert_includes command, '--dry-run true'
      %w[bob lob 0]
    end

    @manager = PgDice::PgSliceManagerFactory.new(PgDice.configuration,
                                                 pg_slice_executor: executor).call
    @manager.add_partitions(table_name: 'comments', future: 10, past: 60, dry_run: true)
    assert_equal 1, call_count
  end
end
