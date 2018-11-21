# frozen_string_literal: true

# Entry point for PartitionManager
module PgDice
  #  PartitionManagerFactory is a class used to build PartitionManagers
  class PartitionManagerFactory
    def initialize(configuration, opts = {})
      @configuration = configuration
      initialize_simple_factories(opts)
      initialize_complex_factories(opts)
      initialize_values(opts)
    end

    def call
      PgDice::PartitionManager.new(logger: @logger_factory.call,
                                   batch_size: @batch_size_factory.call,
                                   approved_tables: @approved_tables_factory.call,
                                   validation: @validation_factory.call,
                                   partition_adder: @partition_adder_factory.call,
                                   partition_lister: @partition_lister_factory.call,
                                   partition_dropper: @partition_dropper_factory.call,
                                   current_date_provider: @current_date_provider)
    end

    private

    def initialize_simple_factories(opts)
      @logger_factory = opts[:logger_factory] ||= proc { @configuration.logger }
      @batch_size_factory = opts[:batch_size_factory] ||= proc { @configuration.batch_size }
      @approved_tables_factory = opts[:approved_tables_factory] ||= proc { @configuration.approved_tables }
    end

    def initialize_complex_factories(opts)
      @validation_factory = opts[:validation_factory] ||= PgDice::ValidationFactory.new(@configuration)
      @partition_adder_factory = opts[:partition_adder_factory] ||= partition_adder_factory
      @partition_lister_factory = opts[:partition_lister_factory] ||= PgDice::PartitionListerFactory.new(@configuration)
      @partition_dropper_factory =
        opts[:partition_dropper_factory] ||= PgDice::PartitionDropperFactory.new(@configuration)
    end

    def initialize_values(opts)
      @current_date_provider = opts[:current_date_provider] ||= proc { Time.now.utc.to_date }
    end

    def partition_adder_factory
      proc do
        pg_slice_manager = PgDice::PgSliceManagerFactory.new(@configuration).call
        ->(all_params) { pg_slice_manager.add_partitions(all_params) }
      end
    end
  end
end
