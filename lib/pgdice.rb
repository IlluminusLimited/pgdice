# frozen_string_literal: true

require 'pg'
require 'open3'
require 'logger'
require 'pgslice'
require 'pgdice/version'
require 'pgdice/configuration'
require 'pgdice/pg_slice_manager'
require 'pgdice/partition_manager'
require 'pgdice/database_connection'
require 'pgdice/helpers/validation_helper'
require 'pgdice/helpers/preparation_helper'
require 'pgdice/helpers/table_dropper_helper'

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

  class << self
    def partition_manager
      unless configuration
        raise PgDice::NotConfiguredError, 'Cannot use partition_manager before PgDice has been configured! '\
          'See README.md for configuration help.'
      end

      @partition_manager ||= PgDice::PartitionManager.new(configuration)
    end

    def preparation_helper
      unless configuration
        raise PgDice::NotConfiguredError, 'Cannot use preparation_helper before PgDice has been configured! '\
          'See README.md for configuration help.'
      end

      @preparation_helper ||= PgDice::PreparationHelper.new(configuration)
    end
  end
end
