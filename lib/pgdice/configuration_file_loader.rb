# frozen_string_literal: true

module PgDice
  #  ConfigurationFileLoader is a class used to load the PgDice configuration file
  class ConfigurationFileLoader
    def initialize(opts = {})
      @config_file = opts[:config_file]
      @config_loader = opts[:config_loader] ||= ->(file) { YAML.safe_load(ERB.new(IO.read(file)).result) }
    end

    def call(config = PgDice::Configuration.new)
      config_file = config.config_file ||= @config_file
      validate_file(config_file)

      config.approved_tables = @config_loader.call(config_file)
                                             .fetch('approved_tables')
                                             .reduce(tables(config)) do |tables, hash|
        tables << PgDice::Table.from_hash(hash)
      end
      config
    end

    private

    def validate_file(config_file)
      unless config_file.present? && File.exist?(config_file)
        raise PgDice::ConfigurationError,
              "File: '#{config_file}' could not be found or does not exist. Is this the correct file path?"
      end
      true
    end

    def tables(config)
      if config.approved_tables(lazy_load: false).is_a?(PgDice::ApprovedTables)
        return config.approved_tables(lazy_load: false)
      end

      PgDice::ApprovedTables.new
    end
  end
end
