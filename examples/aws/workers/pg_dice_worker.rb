# frozen_string_literal: true

# https://github.com/mperham/sidekiq/wiki/Best-Practices
# Sidekiq job parameters must be JSON serializable. That means Ruby symbols are
# lost when they are sent through JSON!
class PgdiceWorker
  include Sidekiq::Worker
  attr_reader :logger
  sidekiq_options queue: :default, backtrace: true, retry: 5

  def initialize(opts = {})
    @pgdice = opts[:pgdice] ||= PgDice
    @logger = opts[:logger] ||= Sidekiq.logger
    @validator = opts[:validator] ||= lambda do |table_name, params|
      @pgdice.public_send(:assert_tables, table_name, params)
    end
  end

  def perform(method, params)
    table_names = params.delete('table_names')
    validate = params.delete('validate').present?
    # Don't pass in params to PgDice if the hash is empty. PgDice will behave differently when params are passed.
    pgdice_params = params.keys.size.zero? ? nil : handle_pgdice_params(params)

    logger.debug { "PgdiceWorker called with method: #{method} and table_names: #{table_names}. Validate: #{validate}" }

    [table_names].flatten.compact.each do |table_name|
      @pgdice.public_send(method, table_name, pgdice_params)
      @validator.call(table_name, pgdice_params) if validate
    end
  end

  private

  def handle_pgdice_params(pgdice_params)
    convert_pgdice_param_values(pgdice_known_symbol_keys(pgdice_params))
  end

  def pgdice_known_symbol_keys(params)
    convertable_keys = ['only']
    params.keys.each do |key|
      params[key.to_sym] = params.delete(key) if convertable_keys.include?(key)
    end
    params
  end

  def convert_pgdice_param_values(params)
    symbolize_values_for_keys = [:only]
    params.each do |key, value|
      params[key] = value.to_sym if symbolize_values_for_keys.include?(key)
    end
    params
  end
end
