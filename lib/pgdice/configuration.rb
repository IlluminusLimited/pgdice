# frozen_string_literal: true

# Entry point for configuration
module PgDice
  class << self
    attr_accessor :configuration

    def configure
      self.configuration ||= Configuration.new
      yield(configuration)
    end
  end

  # Configuration class which holds all configurable values
  class Configuration
    attr_accessor :logger, :database_url, :pg_connection, :database_connection, :pg_slice_manager, :partition_manager

    def initialize
      @logger = Logger.new(STDOUT)
      @database_url = ''
      @database_connection = DatabaseConnection.new(self)
      @pg_slice_manager = PgSliceManager.new(self)
      @partition_manager = PartitionManager.new(self)
    end
  end
end
