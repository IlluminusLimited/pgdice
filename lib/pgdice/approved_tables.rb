# frozen_string_literal: true

module PgDice
  class ApprovedTables
    attr_reader :tables

    def initialize(array = [])
      raise ArgumentError, 'Objects must be a PgDice::Table!' unless array.all? { |item| item.is_a?(PgDice::Table) }

      @tables = array
    end

    def include?(object)
      tables.any? { |table| table.name == object }
    end

    def fetch(key)
      found_table = tables.select { |table| table.name == key }
      raise KeyError, key unless found_table

      found_table
    end

    def [](key)
      tables.select { |table| table.name == key }.first
    end

    def <<(object)
      raise ArgumentError, 'Objects must be a PgDice::Table!' unless object.is_a?(PgDice::Table)

      @tables << object
      self
    end
  end
end
