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
    DEFAULT_VALUES = { logger: Logger.new(STDOUT),
                       database_url: nil,
                       additional_validators: [],
                       approved_tables: [],
                       dry_run: false,
                       table_drop_batch_size: 7 }.freeze

    attr_writer :logger,
                :database_url,
                :additional_validators,
                :approved_tables,
                :dry_run,
                :table_drop_batch_size,
                :database_connection,
                :pg_connection

    attr_accessor :table_dropper,
                  :pg_slice_manager,
                  :partition_manager,
                  :partition_helper,
                  :config_loader

    def initialize(existing_config = nil)
      DEFAULT_VALUES.each do |key, value|
        initialize_value(key, value, existing_config)
      end

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

      raise PgDice::InvalidConfigurationError, 'additional_validators must be an Array!'
    end

    def config_file
      return @config_file unless @config_file.nil?

      raise PgDice::InvalidConfigurationError, 'config_file must be present'
    end

    def approved_tables
      if @approved_tables.is_a?(Array) && @approved_tables.all? { |item| item.is_a?(PgDice::Table) }
        return @approved_tables
      end

      raise PgDice::InvalidConfigurationError, 'approved_tables must be an Array of PgDice::Table!'
    end

    def dry_run
      return @dry_run if [true, false].include?(@dry_run)

      raise PgDice::InvalidConfigurationError, 'dry_run must be either true or false!'
    end

    def table_drop_batch_size
      return @table_drop_batch_size.to_i if @table_drop_batch_size.to_i >= 0

      raise PgDice::InvalidConfigurationError, 'table_drop_batch_size must be a non-negative Integer!'
    end

    def minimum_table_threshold(table_name)
      return approved_tables[table_name].to_i if approved_tables.fetch(table_name).to_i.positive?

      raise PgDice::InvalidConfigurationError, 'approved_tables entries must have a positive Integer for the minimum_table_threshold!'
    end

    # Lazily initialized
    def pg_connection
      @pg_connection ||= PG::Connection.new(database_url)
      return @pg_connection if @pg_connection.respond_to?(:exec)

      raise PgDice::InvalidConfigurationError, 'pg_connection must be present!'
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

    class ConfigFileLoader
      def initialize(config_file)
        @file = config_file
      end

      def call(configuration = PgDice::Configuration.new)
        unless File.exist?(@file)
          raise ArgumentError, "File: #{@file} could not be found or does not exist. Is this the correct configuration file?"
        end

        config_hash = YAML.safe_load(ERB.new(IO.read(@file)).result)
        config_hash.each do |key, value|
          configuration.initialize_value(key, value, nil)
        end
        configuration
      end
    end
  end
end
