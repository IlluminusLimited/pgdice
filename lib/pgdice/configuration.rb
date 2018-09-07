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
    def self.days_ago(days)
      Time.now.utc - days * 24 * 60 * 60
    end

    VALUES = { logger: Logger.new(STDOUT),
               database_url: nil,
               additional_validators: [],
               approved_tables: [],
               keep_tables_newer_than: PgDice::Configuration.days_ago(90),
               dry_run: false }.freeze

    attr_writer :logger,
                :database_url,
                :database_connection,
                :additional_validators,
                :approved_tables,
                :keep_tables_newer_than,
                :dry_run

    attr_accessor :table_dropper,
                  :pg_connection,
                  :pg_slice_manager,
                  :partition_manager,
                  :partition_helper

    def initialize(existing_configuration = nil)
      VALUES.each do |key, value|
        initialize_value(key, value, existing_configuration)
      end
      # @logger = existing_configuration&.logger&.clone || Logger.new(STDOUT)
      # @database_url = existing_configuration&.database_url&.clone || nil
      # @approved_tables = existing_configuration&.approved_tables&.clone || []
      # @additional_validators = existing_configuration&.additional_validators&.clone || []
      # @keep_tables_newer_than = existing_configuration&.keep_tables_newer_than&.clone || days_ago(90)
      # @dry_run = existing_configuration&.dry_run&.clone || false
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

    def additional_validators
      return @additional_validators if @additional_validators.is_a?(Array)
      raise PgDice::InvalidConfigurationError, 'additional_validators must be an array!'
    end

    def approved_tables
      return @approved_tables if @approved_tables.is_a?(Array)
      raise PgDice::InvalidConfigurationError, 'approved_tables must be an array of strings!'
    end

    def keep_tables_newer_than
      return @keep_tables_newer_than if @keep_tables_newer_than.is_a?(Time)
      raise PgDice::InvalidConfigurationError, 'keep_tables_newer_than must be a Time object!'
    end

    def dry_run
      return @dry_run if [true, false].include?(@dry_run)
      raise PgDice::InvalidConfigurationError, 'dry_run must be either true or false!'
    end

    def deep_clone
      PgDice::Configuration.new(self)
    end

    private

    def initialize_value(variable_name, default_value, existing_configuration)
      instance_variable_set("@#{variable_name}", existing_configuration&.send(variable_name)&.clone || default_value)
    end

    def initialize_objects
      @database_connection = PgDice::DatabaseConnection.new(self)
      @partition_manager = PgDice::PartitionManager.new(self)
      @table_dropper = PgDice::TableDropper.new(self)
    end
  end
end
