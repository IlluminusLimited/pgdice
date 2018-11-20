# frozen_string_literal: true

module PgDice
  # Factory for PgDice::Validations
  class ValidationFactory
    def initialize(configuration, opts = {})
      @configuration = configuration
      @partition_lister_factory = opts[:partition_lister_factory] ||= PgDice::PartitionListerFactory.new(@configuration)
    end

    def call
      PgDice::Validation.new(logger: @configuration.logger,
                             database_connection: @configuration.database_connection,
                             partition_lister: @partition_lister_factory.call,
                             approved_tables: @configuration.approved_tables)
    end
  end
end
