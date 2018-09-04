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
  class IllegalTableError < Error
  end
  class PgSliceError < Error
  end
  class NotConfiguredError < Error
  end
  # Rubocop is stupid
  class InvalidConfigurationError < Error
    def initialize(message)
      super("PgDice is not configured properly. #{message}")
    end
  end

  class << self
    def partition_manager
      unless configuration
        raise PgDice::NotConfiguredError, 'Cannot use partition_manager before PgDice has been configured! '\
          'See README.md for configuration help.'
      end

      @partition_manager ||= PgDice::PartitionManager.new(configuration)
    end

    def partition_helper
      unless configuration
        raise PgDice::NotConfiguredError, 'Cannot use partition_helper before PgDice has been configured! '\
          'See README.md for configuration help.'
      end

      @partition_helper ||= PgDice::PartitionHelper.new(configuration)
    end

    def validation
      unless configuration
        raise PgDice::NotConfiguredError, 'Cannot use validation before PgDice has been configured! '\
          'See README.md for configuration help.'
      end

      @validation ||= PgDice::Validation.new(configuration)
    end
  end
end
