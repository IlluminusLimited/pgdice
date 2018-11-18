# frozen_string_literal: true

# Entry point for configuration
module PgDice
  class << self
    attr_accessor :configuration

    def configure(validate_configuration: true)
      self.configuration ||= PgDice::Configuration.new
      yield(configuration)
      configuration.validate! if validate_configuration
    end
  end

  # Configuration class which holds all configurable values
  class Configuration
    DEFAULT_VALUES ||= { logger: Logger.new(STDOUT),
                         database_url: nil,
                         dry_run: false,
                         table_drop_batch_size: 7 }.freeze

    attr_writer :logger,
                :database_url,
                :approved_tables,
                :dry_run,
                :table_drop_batch_size,
                :database_connection,
                :pg_connection,
                :config_file_loader

    attr_accessor :table_dropper,
                  :pg_slice_manager,
                  :partition_manager,
                  :partition_helper,
                  :config_file

    def initialize(existing_config = nil)
      DEFAULT_VALUES.each do |key, value|
        initialize_value(key, value, existing_config)
      end
      @approved_tables = PgDice::ApprovedTables.new(existing_config&.approved_tables(eager_load: true)&.tables)
      initialize_objects
    end

    def validate!
      logger
      logger.debug { 'Validate has been called!' }
      database_url
      database_connection
      approved_tables
      pg_connection
      table_drop_batch_size
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

    def approved_tables(eager_load: false)
      return @approved_tables if eager_load
      raise PgDice::InvalidConfigurationError, 'approved_tables must be an instance of PgDice::ApprovedTables!' unless @approved_tables.respond_to?(:empty?)

      if !config_file_loader.file_loaded? && config_file.present?
        config_file_loader.load_file
        @approved_tables
      end

      @approved_tables
    end

    # Lazily initialized
    def pg_connection
      @pg_connection ||= PG::Connection.new(database_url)
      return @pg_connection if @pg_connection.respond_to?(:exec)

      raise PgDice::InvalidConfigurationError, 'pg_connection must be present!'
    end

    def table_drop_batch_size
      return @table_drop_batch_size.to_i if @table_drop_batch_size.to_i >= 0

      raise PgDice::InvalidConfigurationError, 'table_drop_batch_size must be a non-negative Integer!'
    end

    def dry_run
      return @dry_run if [true, false].include?(@dry_run)

      raise PgDice::InvalidConfigurationError, 'dry_run must be either true or false!'
    end

    def config_file_loader
      @config_file_loader ||= ConfigurationFileLoader.new(self)
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
