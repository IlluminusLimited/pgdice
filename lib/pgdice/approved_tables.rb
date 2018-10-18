# frozen_string_literal: true

module PgDice
  # Hash-like object to contain approved tables. Adds some convenience validation and a simpleish interface.
  class ApprovedTables
    attr_reader :tables

    def initialize(*args)
      raise ArgumentError, 'Objects must be a PgDice::Table!' unless args.all? { |item| item.is_a?(PgDice::Table) }

      @tables = args
    end

    def include?(object)
      tables.any? { |table| table.name == object }
    end

    def [](key)
      tables.select { |table| table.name == key }.first
    end

    def fetch(key)
      found_table = self.[](key)
      raise KeyError, key unless found_table

      found_table
    end

    def <<(object)
      raise ArgumentError, 'Objects must be a PgDice::Table!' unless object.is_a?(PgDice::Table)

      @tables << object
      self
    end
  end
end
