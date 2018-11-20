# frozen_string_literal: true

# Entry point for PartitionManager
module PgDice
  #  PartitionListerFactory is a class used to build PartitionListers
  class PartitionListerFactory
    extend Forwardable

    def_delegators :@configuration, :database_connection

    def initialize(configuration)
      @configuration = configuration
    end

    def call
      PgDice::PartitionLister.new(database_connection: database_connection)
    end
  end
end
