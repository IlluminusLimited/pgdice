# frozen_string_literal: true

# Entry point for TableDropperHelper
module PgDice
  # Simple class used to provide a mechanism that users can hook into if they want to override this
  # default behavior for dropping a table.
  class PartitionDropper
    attr_reader :logger, :database_connection

    def initialize(logger:, database_connection:)
      @logger = logger
      @database_connection = database_connection
    end

    def call(old_partitions)
      logger.info { "Partitions to be deleted are: #{old_partitions}" }

      old_partitions.each do |old_partition|
        database_connection.execute(drop_partition(old_partition))
      end
      old_partitions
    end

    private

    def drop_partition(table_name)
      <<~SQL
        BEGIN;
          DROP TABLE IF EXISTS #{table_name} CASCADE;
        COMMIT;
      SQL
    end
  end
end
