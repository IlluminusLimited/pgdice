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
    DEFAULT_VALUES ||= { logger_factory: proc { Logger.new(STDOUT) },
                         database_url: nil,
                         dry_run: false,
                         batch_size: 7 }.freeze

    attr_writer :logger,
                :logger_factory,
                :database_url,
                :approved_tables,
                :dry_run,
                :batch_size,
                :pg_connection,
                :config_file_loader

    attr_accessor :config_file

    def initialize(existing_config = nil)
      DEFAULT_VALUES.each do |key, value|
        initialize_value(key, value, existing_config)
      end
      @approved_tables = PgDice::ApprovedTables.new(existing_config&.approved_tables(eager_load: true)&.tables)
      initialize_objects
    end

    def validate!
      logger_factory
      database_url
      database_connection
      approved_tables
      pg_connection
      batch_size
    end

    def logger_factory
      return @logger_factory if @logger_factory.respond_to?(:call)

      raise PgDice::InvalidConfigurationError, 'logger_factory must be present!'
    end

    def database_url
      return @database_url unless @database_url.nil?

      raise PgDice::InvalidConfigurationError, 'database_url must be present!'
    end

    def approved_tables(eager_load: false)
      return @approved_tables if eager_load
      unless @approved_tables.respond_to?(:empty?)
        raise PgDice::InvalidConfigurationError, 'approved_tables must be an instance of PgDice::ApprovedTables!'
      end

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

    def batch_size
      return @batch_size.to_i if @batch_size.to_i >= 0

      raise PgDice::InvalidConfigurationError, 'batch_size must be a non-negative Integer!'
    end

    def dry_run
      return @dry_run if [true, false].include?(@dry_run)

      raise PgDice::InvalidConfigurationError, 'dry_run must be either true or false!'
    end

    def config_file_loader
      @config_file_loader ||= ConfigurationFileLoader.new(self)
    end

    def logger
      @logger ||= logger_factory.call
    end

    def partition_manager
      @partition_manager_factory.call
    end

    def partition_helper
      @partition_helper_factory.call
    end

    def validation
      @validation_factory.call
    end

    def database_connection
      @database_connection_factory.call
    end

    def deep_clone
      PgDice::Configuration.new(self)
    end

    private

    def initialize_value(variable_name, default_value, existing_configuration)
      instance_variable_set("@#{variable_name}", existing_configuration&.send(variable_name)&.clone || default_value)
    end

    def initialize_objects
      @partition_manager_factory = PgDice::PartitionManagerFactory.new(self)
      @partition_helper_factory = PgDice::PartitionHelperFactory.new(self)
      @validation_factory = PgDice::ValidationFactory.new(self)
      @database_connection_factory = PgDice::DatabaseConnectionFactory.new(self)
    end
  end
end
