# frozen_string_literal: true

module PgDice
  #  ConfigurationFileLoader is a class used to load the PgDice configuration file
  class ConfigurationFileLoader
    extend Forwardable

    def_delegators :@config, :config_file

    def initialize(config = PgDice::Configuration.new, opts = {})
      @config = config
      @file_validator = opts[:file_validator] ||= lambda do |config_file|
        if config_file.nil?
          raise PgDice::InvalidConfigurationError,
                'Cannot read in nil configuration file! You must set config_file if you leave approved_tables nil!'
        end

        raise PgDice::MissingConfigurationFileError, config_file unless File.exist?(config_file)
      end
      @config_loader = opts[:config_loader] ||= ->(file) { YAML.safe_load(ERB.new(IO.read(file)).result) }
    end

    def call
      @file_validator.call(config_file)

      @config.approved_tables = @config_loader.call(config_file)
                                              .fetch('approved_tables')
                                              .reduce(tables(@config)) do |tables, hash|
        tables << PgDice::Table.from_hash(hash)
      end
      @config
    end

    private

    def tables(config)
      if config.approved_tables(lazy_load: false).is_a?(PgDice::ApprovedTables)
        return config.approved_tables(lazy_load: false)
      end

      PgDice::ApprovedTables.new
    end
  end
end
