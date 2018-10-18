# frozen_string_literal: true

module PgDice
  # Object to represent a
  class Table
    attr_reader :table_base_name, :past, :future, :period

    def initialize(table_base_name:, past: 90, future: 0, period: 'day')
      @table_base_name = table_base_name
      raise ArgumentError, 'past must be an integer' unless past.is_a?(Integer)
      raise ArgumentError, 'future must be an integer' unless future.is_a?(Integer)
      raise ArgumentError, 'period must be a string' unless period.is_a?(String)

      @past = past
      @future = future
      @period = period
    end

    def name
      table_base_name
    end

    def to_h
      { table_base_name: table_base_name,
        past: past,
        future: future,
        period: period }
    end

    def to_s
      to_h.to_s
    end

    def ==(other)
      to_s == other.to_s
    end

    def self.from_hash(hash)
      Table.new(**hash.each_with_object({}) { |(k, v), memo| memo[k.to_sym] = v; })
    end
  end
end
