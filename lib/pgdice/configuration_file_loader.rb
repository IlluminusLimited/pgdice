# frozen_string_literal: true

module PgDice
  #  ConfigurationFileLoader is a class used to load the PgDice configuration file
  class ConfigurationFileLoader
    extend Forwardable

    attr_reader :config

    def_delegators :@config, :config_file, :logger

    def initialize(config = PgDice::Configuration.new, opts = {})
      @config = config
      @file_validator = opts[:file_validator] ||= lambda do |config_file|
        validate_file(config_file)
      end
      @config_loader = opts[:config_loader] ||= lambda do |file|
        logger.debug { "Loading PgDice configuration file: '#{config_file}'" }
        YAML.safe_load(ERB.new(IO.read(file)).result)
      end
      @file_loaded = opts[:file_loaded]
    end

    def load_file
      return if @file_loaded

      @file_loaded = true

      @file_validator.call(config_file)

      @config.approved_tables = @config_loader.call(config_file)
                                              .fetch('approved_tables')
                                              .reduce(tables(@config)) do |tables, hash|
        tables << PgDice::Table.from_hash(hash)
      end
    end

    def file_loaded?
      @file_loaded
    end

    private

    def validate_file(config_file)
      if config_file.nil?
        raise PgDice::InvalidConfigurationError,
              'Cannot read in nil configuration file! You must set config_file if you leave approved_tables nil!'
      end

      raise PgDice::MissingConfigurationFileError, config_file unless File.exist?(config_file)
    end

    def tables(config)
      if config.approved_tables(eager_load: true).is_a?(PgDice::ApprovedTables)
        return config.approved_tables(eager_load: true)
      end

      PgDice::ApprovedTables.new
    end
  end
end
