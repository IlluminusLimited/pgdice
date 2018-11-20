# frozen_string_literal: true

# Entry point for PartitionManager
module PgDice
  #  PartitionManagerFactory is a class used to build PartitionManagers
  class PartitionManagerFactory
    extend Forwardable

    def_delegators :@configuration, :logger, :batch_size, :approved_tables

    def initialize(configuration, opts = {})
      @configuration = configuration
      @validation_factory = opts[:validation_factory] ||= PgDice::ValidationFactory.new(configuration)
      @partition_adder_factory = opts[:partition_adder_factory] ||= PgDice::PgSliceManagerFactory.new(configuration)
      @partition_lister_factory = opts[:partition_lister_factory] ||= PgDice::PartitionListerFactory.new(configuration)
      @partition_dropper_factory = opts[:partition_dropper_factory] ||= PgDice::PartitionDropperFactory.new(configuration)
    end

    def call
      PgDice::PartitionManager.new(logger: logger,
                                   batch_size: batch_size,
                                   approved_tables: approved_tables,
                                   validation: @validation_factory.call,
                                   partition_adder: @partition_adder_factory.call,
                                   partition_lister: @partition_lister_factory.call,
                                   partition_dropper: @partition_dropper_factory.call)
    end
  end
end
