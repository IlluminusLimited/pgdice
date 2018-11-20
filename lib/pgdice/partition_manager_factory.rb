# frozen_string_literal: true

# Entry point for PartitionManager
module PgDice
  #  PartitionManagerFactory is a class used to build PartitionManagers
  class PartitionManagerFactory

    def initialize(configuration, opts = {})
      @configuration = configuration
      @logger_factory = opts[:logger_factory] ||= proc { @configuration.logger }
      @batch_size_factory = opts[:batch_size_factory] ||= proc { @configuration.batch_size }
      @approved_tables_factory = opts[:approved_tables_factory] ||= proc { @configuration.approved_tables }
      @validation_factory = opts[:validation_factory] ||= PgDice::ValidationFactory.new(configuration)
      @partition_adder_factory = opts[:partition_adder_factory] ||= partition_adder_factory
      @partition_lister_factory = opts[:partition_lister_factory] ||= PgDice::PartitionListerFactory.new(configuration)
      @partition_dropper_factory = opts[:partition_dropper_factory] ||= PgDice::PartitionDropperFactory.new(configuration)
    end

    def call
      PgDice::PartitionManager.new(logger: @logger_factory.call,
                                   batch_size: @batch_size_factory.call,
                                   approved_tables: @approved_tables_factory.call,
                                   validation: @validation_factory.call,
                                   partition_adder: @partition_adder_factory.call,
                                   partition_lister: @partition_lister_factory.call,
                                   partition_dropper: @partition_dropper_factory.call)
    end

    private

    def partition_adder_factory
      proc do
        pg_slice_manager = PgDice::PgSliceManagerFactory.new(@configuration).call
        lambda { |all_params| pg_slice_manager.add_partitions(all_params) }
      end
    end
  end
end
