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
    def initialize(direction, table_name, additional_info = '')
      super("Insufficient #{direction} tables exist for table: #{table_name}. #{additional_info}")
    end
  end

  # Error thrown when the count of future tables is less than the expected amount
  class InsufficientFutureTablesError < InsufficientTablesError
    def initialize(table_name, table_count, period)
      super('future', table_name, "Expected: #{table_count} having period of: #{period}.")
    end
  end

  # Error thrown when the count of past tables is less than the expected amount
  class InsufficientPastTablesError < InsufficientTablesError
    def initialize(table_name, additional_info = '')
      super('past', table_name, additional_info)
    end
  end

  # Error thrown if your custom validation evaluates to false
  class CustomValidationError < ValidationError
    def initialize(params, validators, error = nil)
      error_message = "Custom validation failed with params: #{params}. "
      error_message += "Caused by error: #{error} " if error
      error_message += "Validators: #{validators.map { |validator| source_location(validator) }.flatten}"
      super(error_message)
    end

    private

    # Helps users know what went wrong in their custom validators
    def source_location(proc)
      return proc.source_location if proc.respond_to?(:source_location)

      proc.to_s
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
end
