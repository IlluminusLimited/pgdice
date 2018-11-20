# frozen_string_literal: true

require 'pg'
require 'yaml'
require 'json'
require 'open3'
require 'logger'
require 'pgslice'
require 'forwardable'
require 'pgdice/error'
require 'pgdice/table'
require 'pgdice/version'
require 'pgdice/loggable'
require 'pgdice/validation'
require 'pgdice/table_finder'
require 'pgdice/table_dropper'
require 'pgdice/configuration'
require 'pgdice/approved_tables'
require 'pgdice/partition_lister'
require 'pgdice/pg_slice_manager'
require 'pgdice/partition_manager'
require 'pgdice/partition_helper'
require 'pgdice/database_connection'
require 'pgdice/configuration_file_loader'
require 'pgdice/partition_manager_factory'

# This is a stupid comment
module PgDice
  SUPPORTED_PERIODS = { 'day' => 'YYYYMMDD', 'month' => 'YYYYMM', 'year' => 'YYYY' }.freeze

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
