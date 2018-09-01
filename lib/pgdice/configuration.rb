# frozen_string_literal: true

# Entry point for configuration
module PgDice
  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration)
  end

  # Configuration class which holds all configurable values
  class Configuration
    attr_accessor :logger, :database_url, :pg_slice_manager, :partition_manager

    def initialize
      @logger = Logger.new(STDOUT)
      @database_url = build_postgres_url
      @pg_slice_manager = PgSliceManager.new(self)
      @partition_manager = PartitionManager.new(self)
    end

    def build_postgres_url
      # config = Rails.configuration.database_configuration
      # host = config[Rails.env]['host']
      # database = config[Rails.env]['database']
      # username = config[Rails.env]['username']
      # password = config[Rails.env]['password']
      username = 'bob'
      password = 'bob'
      host = 'bob'
      database = 'bob'
      "postgres://#{username}:#{password}@#{host}/#{database}"
    end
  end
end
