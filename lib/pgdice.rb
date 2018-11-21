# frozen_string_literal: true

require 'pg'
require 'yaml'
require 'json'
require 'open3'
require 'logger'
require 'pgslice'
require 'forwardable'
require 'pgdice/version'
require 'pgdice/error'

require 'pgdice/table'

require 'pgdice/table_finder'

require 'pgdice/validation'
require 'pgdice/validation_factory'

require 'pgdice/configuration'
require 'pgdice/configuration_file_loader'

require 'pgdice/approved_tables'

require 'pgdice/partition_lister'
require 'pgdice/partition_lister_factory'

require 'pgdice/pg_slice_manager'
require 'pgdice/pg_slice_manager_factory'

require 'pgdice/partition_helper'
require 'pgdice/partition_helper_factory'

require 'pgdice/partition_manager'
require 'pgdice/partition_manager_factory'

require 'pgdice/partition_dropper'
require 'pgdice/partition_dropper_factory'

require 'pgdice/database_connection'
require 'pgdice/database_connection_factory'

# This is a stupid comment
module PgDice
  SUPPORTED_PERIODS = { 'day' => 'YYYYMMDD', 'month' => 'YYYYMM', 'year' => 'YYYY' }.freeze

  class << self
    def partition_manager
      raise PgDice::NotConfiguredError, 'partition_manager' unless configuration

      configuration.partition_manager
    end

    def partition_helper
      raise PgDice::NotConfiguredError, 'partition_helper' unless configuration

      configuration.partition_helper
    end

    def validation
      raise PgDice::NotConfiguredError, 'validation' unless configuration

      configuration.validation
    end
  end
end
