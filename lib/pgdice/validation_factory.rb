# frozen_string_literal: true

module PgDice
  class ValidationFactory
    def initialize(configuration)
      @configuration = configuration
    end

    def call
      PgDice::Validation.new(logger: @configuration.logger,
                             database_connection: @configuration.database_connection,
                             approved_tables: @configuration.approved_tables)
    end
  end
end
