# frozen_string_literal: true

module PgDice
  # Factory for PgDice::Validations
  class ValidationFactory
    def initialize(configuration, opts = {})
      @configuration = configuration
      @partition_lister_factory = opts[:partition_lister_factory] ||= PgDice::PartitionListerFactory.new(@configuration)
      @period_fetcher_factory = opts[:period_fetcher_factory] ||= PgDice::PeriodFetcherFactory.new(@configuration)
    end

    def call
      PgDice::Validation.new(logger: @configuration.logger,
                             partition_lister: @partition_lister_factory.call,
                             period_fetcher: @period_fetcher_factory.call,
                             approved_tables: @configuration.approved_tables)
    end
  end
end
