# frozen_string_literal: true

# Entry point for PartitionHelper
module PgDice
  # Utility to conditionally add delegated logger or use provided logger
  module Loggable
    def logger
      return @logger if @logger

      @configuration.logger
    end
  end
end
