# frozen_string_literal: true

# Entry point for PartitionManager
module PgDice
  #  PartitionListerFactory is a class used to build PartitionListers
  class PartitionDropperFactory
    extend Forwardable

    def_delegators :@configuration, :logger, :database_connection

    def initialize(configuration)
      @configuration = configuration
    end

    def call
      PgDice::PartitionDropper.new(logger: logger, database_connection: database_connection)
    end
  end
end
