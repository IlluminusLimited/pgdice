# frozen_string_literal: true

require 'test_helper'

class PartitionManagerTest < Minitest::Test
  def test_list_droppable_partitions_excludes_minimum
    manager = PgDice::PartitionManager.new(PgDice.configuration,
                                           batch_size: 4,
                                           current_date_provider: proc { Date.parse('20181028') },
                                           partition_lister: proc { generate_tables })
    assert_equal 7, manager.list_droppable_partitions('comments').size,
                 'With 8 past partitions and 1 minimum required 7 should be returned'
  end

  def test_iterative_delete
    # Given 10 total tables
    # 8 past tables
    # batch size of 4
    # minimum tables of 1
    # we should iterate 2 times,
    # first itertation should drop 4
    # second should drop 3
    # 1 past tables should remain

    tables = generate_tables
    call_count = 0
    dummy_dropper = proc do |partitions|
      tables.shift(partitions.size)
      call_count += partitions.size
    end
    configuration = PgDice.configuration.deep_clone
    configuration.table_dropper = dummy_dropper
    manager = PgDice::PartitionManager.new(configuration,
                                               batch_size: 4,
                                               current_date_provider: proc { Date.parse('20181028') },
                                               partition_lister: proc { tables })
    manager.drop_old_partitions('comments')
    assert_equal 4, call_count, 'The first drop call should only purge 4 tables'
    manager.drop_old_partitions('comments')
    assert_equal 7, call_count, 'The second drop call should purge the remaining 3 tables'
  end

  # def test_future_partitions_can_be_added
  #   partition_helper.partition_table!(table_name)
  #
  #   future_tables = 2
  #
  #   assert @partition_manager.add_new_partitions(table_name, future: future_tables)
  #
  #   assert PgDice.validation.assert_tables(table_name, future: future_tables)
  # end
  #
  # def test_future_partitions_can_be_dry_run
  #   configuration = PgDice.configuration.deep_clone
  #   configuration.dry_run = true
  #   partition_helper.partition_table!(table_name)
  #
  #   future_tables = 2
  #
  #   assert configuration.partition_manager.add_new_partitions(table_name, future: future_tables)
  #
  #   assert PgDice.validation.assert_tables(table_name, future: 0, past: 0)
  # end
  #
  # def test_future_partitions_blows_up_on_unpartitioned_table
  #   assert_raises(PgDice::PgSliceError) do
  #     @partition_manager.add_new_partitions(table_name, future: 2)
  #   end
  # end
  #
  # def test_old_partitions_can_be_listed
  #   partition_helper.partition_table!(table_name, past: 2, future: 1)
  #
  #   assert_equal 2, @partition_manager.list_partitions(table_name, older_than: today).size
  #   assert PgDice.validation.assert_tables(table_name, past: 2, future: 1)
  # end
  #
  # def test_drop_old_partitions_can_be_dry_run
  #   configuration = PgDice.configuration.deep_clone
  #   configuration.dry_run = true
  #
  #   partition_helper.partition_table!(table_name, past: 2)
  #
  #   assert_equal 0, configuration.partition_manager.drop_old_partitions(table_name).size
  #   assert PgDice.validation.assert_tables(table_name, past: 2)
  # end
  #
  # def test_old_partitions_can_be_dropped
  #   partition_helper.partition_table!(table_name, past: 2)
  #
  #   # The minimum partitions required on this table is 1
  #   assert_equal 1, @partition_manager.drop_old_partitions(table_name).size
  #   assert PgDice.validation.assert_tables(table_name, past: 1)
  # end
  #
  # def test_drop_old_partitions_uses_batch_size
  #   batch_size, minimum_tables = batch_size_and_minimum_tables
  #   partition_helper.partition_table!(table_name, past: (batch_size + minimum_tables))
  #
  #   assert_equal batch_size, @partition_manager.drop_old_partitions(table_name).size
  #   assert PgDice.validation.assert_tables(table_name, past: minimum_tables)
  # end
  #
  # def test_will_not_drop_more_than_minimum
  #   PgDice.partition_helper.partition_table!(table_name, past: 3)
  #   assert_equal 2, PgDice.partition_manager.drop_old_partitions(table_name).size
  #   assert PgDice.validation.assert_tables(table_name, past: 1)
  # end
  #
  # def test_add_future_partitions_checks_allowed_tables
  #   assert_raises(PgDice::IllegalTableError) do
  #     @partition_manager.add_new_partitions('bob')
  #   end
  # end
  #
  # def test_drop_old_partitions_checks_allowed_tables
  #   assert_raises(PgDice::IllegalTableError) do
  #     @partition_manager.drop_old_partitions('bob')
  #   end
  # end
  #
  # def test_cannot_drop_more_than_minimum_tables
  #   table_name = 'posts'
  #   PgDice.partition_helper.partition_table!(table_name, past: 10)
  #   assert_empty PgDice.partition_manager.list_droppable_partitions(table_name, older_than: today)
  #   assert_empty PgDice.partition_manager.drop_old_partitions(table_name)
  # ensure
  #   partition_helper.undo_partitioning('posts')
  # end
  #
  # # Comments table is configured to have a minimum_table_threshold of 1 table
  # # Thus there should be no droppable tables if looking older than yesterday.
  # def test_list_droppable_partitions
  #   PgDice.partition_helper.partition_table!(table_name, past: 30)
  #   droppable_partitions = PgDice.partition_manager.list_droppable_partitions(table_name, older_than: today)
  #   assert_equal 29, droppable_partitions.size, 'Droppable partitions should include all tables past the minimum table threshold which should be set to 1 for comments table'
  # end
  #
  # def test_old_tables_dropped_in_future
  #   PgDice.partition_helper.partition_table!(table_name, past: 2, future: 3)
  #   assert_equal 2, PgDice::PartitionManager.new(PgDice.configuration,
  #                                                current_date_provider: proc { tomorrow.to_date })
  #                                           .list_droppable_partitions(table_name, older_than: tomorrow).size
  # end
  #
  # private
  #
  # def batch_size_and_minimum_tables
  #   batch_size = PgDice.configuration.batch_size
  #   minimum_tables = PgDice.configuration.approved_tables[table_name].past
  #   [batch_size, minimum_tables]
  # end

  private

  def generate_tables
    %w[comments_20181020 comments_20181021 comments_20181022 comments_20181023 comments_20181024
       comments_20181025 comments_20181026 comments_20181027 comments_20181028 comments_20181029]
  end
end
