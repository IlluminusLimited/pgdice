# frozen_string_literal: true

module PgDice
  module ValidationHelper
    def self.assert_future_tables(table_name, future_tables, interval = 'days')
      sql = <<~SQL
        SELECT 1
        FROM pg_catalog.pg_class pg_class
        INNER JOIN pg_catalog.pg_namespace pg_namespace ON pg_namespace.oid = pg_class.relnamespace
        WHERE pg_class.relkind = 'r'
          AND pg_namespace.nspname = 'public'
          AND pg_class.relname = '#{table_name}_' || to_char(NOW() + INTERVAL '#{future_tables} #{interval}', 'YYYYMMDD')
      SQL

      response = ActiveRecord::Base.connection.execute(sql)
      unless response.values.size == 1
        raise InsufficientFutureTablesError, "Insufficient future tables exist for table: #{table_name}. "\
"Expected: #{future_tables} having intervals of: #{interval}"
      end
    end

    def validate_parameters(params)
      table_name = params.fetch(:table_name)
      unless APPROVED_TABLES.include?(table_name)
        raise IllegalTableError, "Table: #{table_name} is not in the list of approved tables!"
      end
    end
  end
end
