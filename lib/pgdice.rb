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
require 'pgdice/helpers/database_helper'
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

  class << self
    def partition_manager
      self.configuration ||= PgDice::Configuration.new
      @partition_manager ||= PgDice::PartitionManager.new(self.configuration)
    end
  end
end
