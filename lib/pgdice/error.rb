# frozen_string_literal: true

module PgDice
  # PgDice parent error class
  class Error < StandardError
  end

  # Error thrown when PgSlice returns an error code
  class PgSliceError < Error
  end

  # Generic validation error
  class ValidationError < Error
  end

  # Error thrown if a user tries to operate on a table that is not in the ApprovedTables object.
  class IllegalTableError < ValidationError
  end

  # Error thrown when a user attempts to manipulate partitions on a table that is not partitioned
  class TableNotPartitionedError < Error
  end

  # Generic error for table counts
  class InsufficientTablesError < Error
    def initialize(direction, table_name, expected, period, found_count)
      super("Insufficient #{direction} tables exist for table: #{table_name}. "\
      "Expected: #{expected} having period of: #{period} but found: #{found_count}")
    end
  end

  # Error thrown when the count of future tables is less than the expected amount
  class InsufficientFutureTablesError < InsufficientTablesError
    def initialize(table_name, expected, period, found_count)
      super('future', table_name, expected, period, found_count)
    end
  end

  # Error thrown when the count of past tables is less than the expected amount
  class InsufficientPastTablesError < InsufficientTablesError
    def initialize(table_name, expected, period, found_count)
      super('past', table_name, expected, period, found_count)
    end
  end

  # Generic configuration error
  class ConfigurationError < Error
  end

  # Error thrown if you call a method that requires configuration first
  class NotConfiguredError < ConfigurationError
    def initialize(method_name)
      super("Cannot use #{method_name} before PgDice has been configured! "\
          'See README.md for configuration help.')
    end
  end

  # Error thrown if you provide bad data in a configuration
  class InvalidConfigurationError < ConfigurationError
    def initialize(message)
      super("PgDice is not configured properly. #{message}")
    end
  end

  # Error thrown if the config file specified does not exist.
  class MissingConfigurationFileError < ConfigurationError
    def initialize(config_file)
      super("File: '#{config_file}' could not be found or does not exist. Is this the correct file path?")
    end
  end
end
