# frozen_string_literal: true

module PgDice
  # Hash-like object to contain approved tables. Adds some convenience validation and a simpleish interface.
  class ApprovedTables
    attr_reader :tables
    extend Forwardable

    def_delegators :@tables, :size, :empty?, :map, :each, :each_with_index, :to_a

    def initialize(*args)
      @tables = args.flatten.compact

      raise ArgumentError, 'Objects must be a PgDice::Table!' unless tables.all? { |item| item.is_a?(PgDice::Table) }
    end

    def [](arg)
      key = check_string_args(arg)
      tables.select { |table| table.name == key }.first
    end

    def include?(arg)
      key = check_string_args(arg)
      return true if self.[](key)

      false
    end

    def fetch(arg)
      key = check_string_args(arg)
      found_table = self.[](key)
      raise PgDice::IllegalTableError, "Table name: '#{key}' is not in the list of approved tables!" unless found_table

      found_table
    end

    def <<(object)
      raise ArgumentError, 'Objects must be a PgDice::Table!' unless object.is_a?(PgDice::Table)

      object.validate!
      return self if include?(object.name)

      @tables << object
      self
    end

    def smash(table_name, override_parameters)
      fetch(table_name).smash(override_parameters)
    end

    def ==(other)
      tables.sort == other.tables.sort
    end

    private

    def check_string_args(key)
      raise ArgumentError, 'key must be a String' unless key.is_a?(String)

      key
    end
  end
end
