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
    attr_writer :logger, :database_url, :database_connection

    attr_accessor :approved_tables,
                  :additional_validators,
                  :table_dropper,
                  :pg_connection,
                  :pg_slice_manager,
                  :partition_manager,
                  :partition_helper

    def initialize(existing_configuration = nil)
      @logger = existing_configuration&.logger&.clone || Logger.new(STDOUT)
      @database_url = existing_configuration&.database_url&.clone || nil
      @approved_tables = existing_configuration&.approved_tables&.clone || []
      @additional_validators = existing_configuration&.additional_validators&.clone || []
      initialize_objects
    end

    def logger
      return @logger unless @logger.nil?
      raise PgDice::InvalidConfigurationError, 'logger must be present!'
    end

    def database_url
      return @database_url unless @database_url.nil?
      raise PgDice::InvalidConfigurationError, 'database_url must be present!'
    end

    def database_connection
      return @database_connection unless @database_connection.nil?
      raise PgDice::InvalidConfigurationError, 'database_connection must be present!'
    end

    def deep_clone
      PgDice::Configuration.new(self)
    end

    private

    def initialize_objects
      @database_connection = PgDice::DatabaseConnection.new(self)
      @partition_manager = PgDice::PartitionManager.new(self)
      @table_dropper = PgDice::TableDropper.new(self)
    end
  end
end
