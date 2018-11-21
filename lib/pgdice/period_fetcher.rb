# frozen_string_literal: true

module PgDice
  # Used to find the period of a postgres table using the comment on the table created by pgslice
  class PeriodFetcher
    def initialize(query_executor:)
      @query_executor = query_executor
    end

    def call(params)
      sql = build_table_comment_sql(params.fetch(:table_name), params.fetch(:schema))
      values = @query_executor.call(sql)
      convert_comment_to_hash(values.first)[:period]
    end

    private

    def convert_comment_to_hash(comment)
      return {} unless comment

      comment.split(',').reduce({}) do |hash, key_value_pair|
        key, value = key_value_pair.split(':')
        hash.merge(key.to_sym => value)
      end
    end

    def build_table_comment_sql(table_name, schema)
      "SELECT obj_description('#{schema}.#{table_name}'::REGCLASS) AS comment"
    end
  end
end
