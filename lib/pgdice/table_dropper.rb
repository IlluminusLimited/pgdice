# frozen_string_literal: true

# Entry point for TableDropperHelper
module PgDice
  # Simple class used to provide a mechanism that users can hook into if they want to override this
  # default behavior for dropping a table.
  class TableDropper
    def initialize(configuration = PgDice::Configuration.new)
      @configuration = configuration
    end

    def call(table_to_drop, logger)
      sql = drop_partition(table_to_drop)
      logger.debug { "TableDropper executing: #{sql}" }
      @configuration.database_connection.execute(sql)
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
