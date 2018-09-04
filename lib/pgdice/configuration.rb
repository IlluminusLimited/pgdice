# frozen_string_literal: true

# Entry point for configuration
module PgDice
  class << self
    attr_accessor :configuration

    def configure
      self.configuration ||= PgDice::Configuration.new
      yield(configuration)
    end
  end

  # Configuration class which holds all configurable values
  class Configuration
    attr_writer :logger, :database_url

    attr_accessor :pg_connection,
                  :database_connection,
                  :pg_slice_manager,
                  :partition_manager,
                  :approved_tables,
                  :preparation_helper,
                  :database_helper,
                  :table_dropper_helper,
                  :additional_validators

    def initialize
      @logger = Logger.new(STDOUT)
      @approved_tables = []
      @additional_validators = []
      @database_connection = PgDice::DatabaseConnection.new(self)
      @partition_manager = PgDice::PartitionManager.new(self)
      @table_dropper_helper = PgDice::TableDropperHelper.new(self)
    end

    def logger
      return @logger unless @logger.nil?
      raise PgDice::InvalidConfigurationError, 'logger must be present!'
    end

    def database_url
      return @database_url unless @database_url.nil?
      raise PgDice::InvalidConfigurationError, 'database_url must be present!'
    end
  end
end
