# frozen_string_literal: true

module PgDice
  # Hash-like object to contain approved tables. Adds some convenience validation and a simpleish interface.
  class ApprovedTables
    attr_reader :tables

    def initialize(*args)
      raise ArgumentError, 'Objects must be a PgDice::Table!' unless args.all? { |item| item.is_a?(PgDice::Table) }

      @tables = Set.new(args)
    end

    def [](key)
      tables.select { |table| table.name == key }.first
    end

    def fetch(key)
      raise ArgumentError, 'key must be a String' unless key.is_a?(String)

      found_table = self.[](key)
      raise PgDice::IllegalTableError, "Table name: '#{key}' is not in the list of approved tables!" unless found_table

      found_table
    end

    def include?(object)
      fetch(object)
      true
    end

    def <<(object)
      raise ArgumentError, 'Objects must be a PgDice::Table!' unless object.is_a?(PgDice::Table)

      object.validate!
      @tables << object
      self
    end

    # def validate!(params)
    #   validate_table_name(params)
    #
    #   true
    # end
  end
end
