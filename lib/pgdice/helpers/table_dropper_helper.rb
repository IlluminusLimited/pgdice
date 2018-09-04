# frozen_string_literal: true

# Entry point for TableDropperHelper
module PgDice
  # Simple class used to provide a mechanism that users can hook into if they want to override this
  # default behavior for dropping a table.
  class TableDropperHelper
    def initialize(configuration = Configuration.new)
      @configuration = configuration
    end

    def call(old_partition)
      @configuration.database_connection.execute(drop_partition(old_partition))
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
