# frozen_string_literal: true

# Entry point for PartitionManager
module PgDice
  #  PartitionManagerFactory is a class used to build PartitionManagers
  class PartitionHelperFactory
    extend Forwardable

    def_delegators :@configuration, :logger, :approved_tables

    def initialize(configuration, opts = {})
      @configuration = configuration
      @validation_factory = opts[:validation_factory] ||= PgDice::ValidationFactory.new(configuration)
      @pg_slice_manager_factory = opts[:pg_slice_manager_factory] ||= PgDice::PgSliceManagerFactory.new(configuration)
    end

    def call
      PgDice::PartitionHelper.new(logger: logger,
                                  approved_tables: approved_tables,
                                  validation: @validation_factory.call,
                                  pg_slice_manager: @pg_slice_manager_factory.call)
    end
  end
end
