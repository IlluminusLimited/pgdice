# frozen_string_literal: true

# Entry point for PartitionManager
module PgDice
  #  PartitionManagerFactory is a class used to build PartitionManagers
  class PgSliceManagerFactory
    extend Forwardable

    def_delegators :@configuration, :logger, :database_url, :dry_run

    def initialize(configuration)
      @configuration = configuration
    end

    def call
      PgDice::PgSliceManager.new(logger: logger, database_url: database_url, dry_run: dry_run)
    end
  end
end
