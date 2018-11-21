# frozen_string_literal: true

require 'test_helper'

class PartitionManagerTest < Minitest::Test
  def setup
    dummy_dropper = setup_tattletale
    @partition_manager = PgDice::PartitionManagerFactory.new(PgDice.configuration,
                                                             batch_size_factory: proc { 4 },
                                                             current_date_provider: proc { Date.parse('20181028') },
                                                             partition_lister_factory: proc { proc { @tables } },
                                                             partition_dropper_factory: proc { dummy_dropper }).call
  end

  def setup_tattletale
    @tables = generate_tables
    @call_count = 0
    proc do |partitions|
      @tables.shift(partitions.size)
      @call_count += partitions.size
    end
  end

  def test_list_droppable_partitions_excludes_minimum
    assert_equal 7, @partition_manager.list_droppable_partitions('comments').size,
                 'With 8 past partitions and 1 minimum required 7 should be returned'
  end

  # Given 10 total tables
  # 8 past tables
  # batch size of 4
  # minimum tables of 1
  # we should iterate 2 times,
  # first itertation should drop 4
  # second should drop 3
  # 1 past tables should remain
  def test_iterative_delete
    @partition_manager.drop_old_partitions('comments')
    assert_equal 4, @call_count, 'The first drop call should purge 4 tables'
    @partition_manager.drop_old_partitions('comments')
    assert_equal 7, @call_count, 'The second drop call should purge the remaining 3 tables'
  end

  def test_add_new_partitions_checks_allowed_tables
    assert_raises(PgDice::IllegalTableError) do
      @partition_manager.add_new_partitions('bob')
    end
  end

  def test_drop_old_partitions_checks_allowed_tables
    assert_raises(PgDice::IllegalTableError) do
      @partition_manager.drop_old_partitions('bob')
    end
  end

  def test_list_partitions
    assert_equal generate_tables, @partition_manager.list_partitions('comments')
  end

  def test_list_batched_droppable_partitions
    assert_equal generate_tables.first(4), @partition_manager.list_droppable_partitions_by_batch_size('comments')
  end

  private

  def generate_tables
    %w[comments_20181020 comments_20181021 comments_20181022 comments_20181023 comments_20181024
       comments_20181025 comments_20181026 comments_20181027 comments_20181028 comments_20181029]
  end
end
