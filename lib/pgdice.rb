# frozen_string_literal: true

require 'pg'
require 'open3'
require 'logger'
require 'pgslice'
require 'pgdice/version'
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
  class InsufficientFutureTablesError < Error
  end
  class PgSliceError < Error
  end

  class ValidationError < Error
  end
  class IllegalTableError < ValidationError
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

    def source_location(proc)
      return proc.source_location if proc.respond_to?(:source_location)
      proc.to_s
    end
  end

  # Rubocop is stupid
  class NotConfiguredError < Error
    def initialize(method_name)
      super("Cannot use #{method_name} before PgDice has been configured! "\
          'See README.md for configuration help.')
    end
  end

  # Rubocop is stupid
  class InvalidConfigurationError < Error
    def initialize(message)
      super("PgDice is not configured properly. #{message}")
    end
  end

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
