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
    attr_accessor :logger,
                  :database_url,
                  :pg_connection,
                  :database_connection,
                  :pg_slice_manager,
                  :partition_manager,
                  :approved_tables,
                  :preparation_helper,
                  :database_helper,
                  :table_dropper_helper,
                  :additional_validators

    def initialize
      initialize_simple_params
      @database_connection = PgDice::DatabaseConnection.new(self)
      @partition_manager = PgDice::PartitionManager.new(self)
      @table_dropper_helper = PgDice::TableDropperHelper.new(self)
    end

    private

    def initialize_simple_params
      @logger = Logger.new('log/pgdice.log')
      @database_url = ''
      @approved_tables = []
      @additional_validators = []
    end
  end
end
