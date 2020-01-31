# frozen_string_literal: true

# Tasks that we can use to maintain partitioned tables over time
# You can override the default params hash by passing it in to the method calls.
# The default params are defined inside each method.
#
# Also, as far as the string keys for hashes go:
# https://github.com/mperham/sidekiq/wiki/Best-Practices
# Sidekiq job parameters must be JSON serializable. That means Ruby symbols are
# lost when they are sent through JSON!
class DatabaseTasks
  def initialize(opts = {})
    @pgdice = opts[:pgdice] ||= PgDice
    @task_runner = opts[:task_runner] ||= ->(method, params) { PgdiceWorker.perform_async(method, params) }
  end

  def add_new_partitions(params = {})
    all_params = { 'table_names' => table_names, 'only' => 'future', 'validate' => true }.merge(params)
    @task_runner.call('add_new_partitions', all_params)
  end

  def drop_old_partitions(params = {})
    all_params = { 'table_names' => table_names, 'only' => 'past', 'validate' => true }.merge(params)
    @task_runner.call('drop_old_partitions', all_params)
  end

  def assert_tables(params = {})
    all_params = { 'table_names' => table_names, 'validate' => false }.merge(params)
    @task_runner.call('assert_tables', all_params)
  end

  private

  def table_names
    @pgdice.approved_tables.map(&:name)
  end
end
