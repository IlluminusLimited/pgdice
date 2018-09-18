# frozen_string_literal: true

require 'pg'
require 'open3'
require 'logger'
require 'pgslice'
require 'pgdice/version'
require 'pgdice/loggable'
require 'pgdice/validation'
require 'pgdice/table_dropper'
require 'pgdice/configuration'
require 'pgdice/pg_slice_manager'
require 'pgdice/partition_manager'
require 'pgdice/partition_helper'
require 'pgdice/database_connection'

# This is a stupid comment
module PgDice
  class Error < StandardError
  end
  class PgSliceError < Error
  end
  class ValidationError < Error
  end
  class IllegalTableError < ValidationError
  end
  class TableNotPartitionedError < Error
  end

  # Rubocop is stupid
  class InsufficientTablesError < Error
    def initialize(direction, table_name, table_count, period)
      super("Insufficient #{direction} tables exist for table: #{table_name}. "\
        "Expected: #{table_count} having period of: #{period}")
    end
  end

  # Rubocop is stupid
  class InsufficientFutureTablesError < InsufficientTablesError
    def initialize(table_name, table_count, period)
      super('future', table_name, table_count, period)
    end
  end

  # Rubocop is stupid
  class InsufficientPastTablesError < InsufficientTablesError
    def initialize(table_name, table_count, period)
      super('past', table_name, table_count, period)
    end
  end

  # Rubocop is stupid
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

  class ConfigurationError < Error
  end

  # Rubocop is stupid
  class NotConfiguredError < ConfigurationError
    def initialize(method_name)
      super("Cannot use #{method_name} before PgDice has been configured! "\
          'See README.md for configuration help.')
    end
  end

  # Rubocop is stupid
  class InvalidConfigurationError < ConfigurationError
    def initialize(message)
      super("PgDice is not configured properly. #{message}")
    end
  end

  SUPPORTED_PERIODS = { day: 'YYYYMMDD', month: 'YYYYMM', year: 'YYYY' }.freeze

  class << self
    def partition_manager
      raise PgDice::NotConfiguredError, 'partition_manager' unless configuration

      @partition_manager ||= PgDice::PartitionManager.new(configuration)
    end

    def partition_helper
      raise PgDice::NotConfiguredError, 'partition_helper' unless configuration

      @partition_helper ||= PgDice::PartitionHelper.new(configuration)
    end

    def validation
      raise PgDice::NotConfiguredError, 'validation' unless configuration

      @validation ||= PgDice::Validation.new(configuration)
    end
  end
end
