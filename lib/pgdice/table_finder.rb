# frozen_string_literal: true

module PgDice
  # Module which is a collection of methods used by PartitionManager to find and list tables
  class TableFinder
    include PgDice::Loggable
    extend Forwardable

    def_delegators :@configuration, :batch_size, :approved_tables, :table_dropper

    def initialize(configuration = PgDice::Configuration.new)
      @configuration = configuration
    end

    def build_partition_table_fetch_sql(params = {})
      schema = params.fetch(:schema, 'public')
      base_table_name = params.fetch(:table_name)

      <<~SQL
        SELECT tablename
        FROM pg_tables
        WHERE schemaname = '#{schema}'
          AND tablename ~ '^#{base_table_name}_\\d+$'
        ORDER BY tablename
      SQL
    end
  end
end
