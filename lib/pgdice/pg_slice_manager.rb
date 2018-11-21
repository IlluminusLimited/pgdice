# frozen_string_literal: true

# Entry point for PgSliceManager
module PgDice
  # PgSliceManager is a wrapper around PgSlice
  class PgSliceManager
    include PgDice::LogHelper

    attr_reader :logger, :database_url

    def initialize(logger:, database_url:, pg_slice_executor:, dry_run: false)
      @logger = logger
      @database_url = database_url
      @dry_run = dry_run
      @pg_slice_executor = pg_slice_executor
    end

    def prep(params = {})
      table_name = params.fetch(:table_name)
      column_name = params.fetch(:column_name)
      period = params.fetch(:period)
      run_pgslice("prep #{table_name} #{column_name} #{period}", params[:dry_run])
    end

    def fill(params = {})
      table_name = params.fetch(:table_name)
      swapped = params.fetch(:swapped, '')
      swapped = '--swapped' if swapped.to_s.casecmp('true').zero?

      run_pgslice("fill #{table_name} #{swapped}", params[:dry_run])
    end

    def analyze(params = {})
      table_name = params.fetch(:table_name)
      swapped = params.fetch(:swapped, '')
      swapped = '--swapped' if swapped.to_s.casecmp('true').zero?

      run_pgslice("analyze #{table_name} #{swapped}", params[:dry_run])
    end

    def swap(params = {})
      table_name = params.fetch(:table_name)
      run_pgslice("swap #{table_name}", params[:dry_run])
    end

    def add_partitions(params = {})
      table_name = params.fetch(:table_name)
      future_tables = params.fetch(:future, nil)
      future_tables = "--future #{Integer(future_tables)}" if future_tables

      past_tables = params.fetch(:past, nil)
      past_tables = "--past #{Integer(past_tables)}" if past_tables

      intermediate = params.fetch(:intermediate, nil)
      intermediate = '--intermediate' if intermediate.to_s.casecmp('true').zero?

      run_pgslice("add_partitions #{table_name} #{intermediate} #{future_tables} #{past_tables}", params[:dry_run])
    end

    def unprep!(params = {})
      table_name = params.fetch(:table_name)

      run_pgslice("unprep #{table_name}", params[:dry_run])
    end

    def unswap!(params = {})
      table_name = params.fetch(:table_name)

      run_pgslice("unswap #{table_name}", params[:dry_run])
    end

    def unprep(params = {})
      table_name = params.fetch(:table_name)

      run_pgslice("unprep #{table_name}", params[:dry_run])
    rescue PgSliceError => error
      logger.error { "Rescued PgSliceError: #{error}" }
      false
    end

    def unswap(params = {})
      table_name = params.fetch(:table_name)

      run_pgslice("unswap #{table_name}", params[:dry_run])
    rescue PgSliceError => error
      logger.error { "Rescued PgSliceError: #{error}" }
      false
    end

    private

    def run_pgslice(argument_string, dry_run)
      command = build_pg_slice_command(argument_string, dry_run)

      stdout, stderr, status = run_and_log(command)

      if status.to_i.positive?
        raise PgDice::PgSliceError,
              "pgslice with arguments: '#{argument_string}' failed with status: '#{status}' "\
                 "STDOUT: '#{stdout}' STDERR: '#{stderr}'"
      end
      true
    end

    def build_pg_slice_command(argument_string, dry_run)
      argument_string = argument_string.strip
      $stdout.flush
      $stderr.flush
      command = "pgslice #{argument_string}"
      command += ' --dry-run true' if @dry_run || dry_run
      command = squish(command)
      logger.info { "Running pgslice command: '#{command}'" }
      command + " --url #{database_url}"
    end

    def log_result(stdout, stderr)
      logger.debug { "pgslice STDERR: #{stderr}" } unless blank?(stderr)
      logger.debug { "pgslice STDOUT: #{stdout}" } unless blank?(stdout)
    end

    def log_status(status)
      logger.debug { "pgslice exit status: #{status}" } unless blank?(status) || status.to_i.zero?
    end

    def run_and_log(command)
      PgDice::LogHelper.log_duration('PgSlice', logger) do
        stdout, stderr, status = @pg_slice_executor.call(command)
        log_result(stdout, stderr)
        log_status(status)
        [stdout, stderr, status]
      end
    end
  end
end
