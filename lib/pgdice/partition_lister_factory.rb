# frozen_string_literal: true

# Entry point for PartitionManager
module PgDice
  #  PartitionListerFactory is a class used to build PartitionListers
  class PartitionListerFactory
    extend Forwardable

    def_delegators :@configuration, :database_connection

    def initialize(configuration, opts = {})
      @configuration = configuration
      @query_executor = opts[:query_executor] ||= lambda do |sql|
        database_connection.execute(sql).values.flatten
      end
    end

    def call
      PgDice::PartitionLister.new(query_executor: @query_executor)
    end
  end
end
