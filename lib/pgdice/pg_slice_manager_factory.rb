# frozen_string_literal: true

# Entry point for PartitionManager
module PgDice
  #  PartitionManagerFactory is a class used to build PartitionManagers
  class PgSliceManagerFactory
    extend Forwardable
    include PgDice::LogHelper

    def_delegators :@configuration, :logger, :database_url, :dry_run

    def initialize(configuration, opts = {})
      @configuration = configuration
      @pg_slice_executor = opts[:pg_slice_executor] ||= executor
    end

    def call
      PgDice::PgSliceManager.new(logger: logger,
                                 database_url: database_url,
                                 pg_slice_executor: @pg_slice_executor,
                                 dry_run: dry_run)
    end

    private

    def executor
      lambda do |command|
        results = Open3.capture3(command)
        stdout, stderr = results.first(2).map { |output| squish(output.to_s) }
        status = results[2].exitstatus.to_s
        [stdout, stderr, status]
      end
    end
  end
end
