# frozen_string_literal: true

module PgDice
  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration)
  end

  class Configuration
    attr_accessor :database_url

    def initialize
      @database_url = nil
    end
  end
end
