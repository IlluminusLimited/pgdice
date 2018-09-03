# frozen_string_literal: true

# Collection of utilities that are necessary to achieve compliance with pg_slice
class DatabaseHelper
  # Grabs only tables that start with the base_table_name and end in numbers
  def fetch_partition_tables(base_table_name, opts = {})
    schema = opts[:schema] ||= 'public'
    limit = opts[:limit] || nil

    sql = build_partition_table_fetch_sql(base_table_name, schema, limit)

    partition_tables = ActiveRecord::Base.connection.execute(sql).values.flatten
    logger.debug { "Table: #{schema}.#{base_table_name} has partition_tables: #{partition_tables}" }
    partition_tables
  end

  # Typical partition comments looks like: column:created_at,period:day,cast:date
  def extract_partition_template_from_comment(table_name, schema = 'public')
    sql = build_table_comment_sql(table_name, schema)

    comment = ActiveRecord::Base.connection.execute(sql).values.flatten.first
    logger.debug { "Table: #{schema}.#{table_name} has comment: #{comment}" }

    partition_template = {}

    comment.split(',').each do |key_value_pair|
      key, value = key_value_pair.split(':')
      partition_template[key.to_sym] = value
    end

    partition_template
  end

  private

  def build_table_comment_sql(table_name, schema)
    <<~SQL
      SELECT obj_description('#{schema}.#{table_name}'::REGCLASS) AS comment
    SQL
  end

  def build_partition_table_fetch_sql(base_table_name, schema, limit)
    sql = <<~SQL
      SELECT tablename
      FROM pg_tables
      WHERE schemaname = '#{schema}'
        AND tablename ~ '^#{base_table_name}_\d+$'
      ORDER BY tablename
    SQL

    sql += " LIMIT #{limit}" if limit
    sql
  end
end
