# frozen_string_literal: true

module PgDice
  # Object to represent a table's configuration in the context of PgDice.
  class Table
    include Comparable
    attr_reader :table_name
    attr_accessor :past, :future, :column_name, :period, :schema

    def initialize(table_name:, past: 90, future: 0, column_name: 'created_at', period: 'day', schema: 'public')
      raise ArgumentError, 'table_name must be a string' unless table_name.is_a?(String)

      @table_name = table_name
      @past = past
      @future = future
      @column_name = column_name
      @period = period
      @schema = schema
    end

    def validate!
      check_type(:past, Integer)
      check_type(:future, Integer)
      check_type(:column_name, String)
      check_type(:period, String)
      check_type(:schema, String)
      unless PgDice::SUPPORTED_PERIODS.include?(period)
        raise ArgumentError,
              "Period must be one of: #{PgDice::SUPPORTED_PERIODS.keys}. Value: #{period} is not valid."
      end
      true
    end

    def name
      table_name
    end

    def full_name
      "#{schema}.#{name}"
    end

    def to_h
      { table_name: table_name,
        past: past,
        future: future,
        column_name: column_name,
        period: period,
        schema: schema }
    end

    def to_s
      "#{schema}.#{name}: <past: #{past}, future: #{future}, column_name: #{column_name}, period: #{period}>"
    end

    def smash(override_parameters)
      to_h.merge!(override_parameters)
    end

    def ==(other)
      to_h == other.to_h
    end

    def <=>(other)
      table_name <=> other.table_name
    end

    # Get expected size of this configured table (past + present + future table counts)
    def size
      past + future + 1
    end

    def self.from_hash(hash)
      Table.new(**hash.each_with_object({}) { |(k, v), memo| memo[k.to_sym] = v; })
    end

    private

    def check_type(field, expected_type)
      unless send(field).is_a?(expected_type)
        raise ArgumentError,
              "PgDice::Table: #{name} failed validation on field: #{field}. "\
                "Expected type of: #{expected_type} but found #{send(field).class}"
      end
      true
    end
  end
end
