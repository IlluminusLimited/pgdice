# frozen_string_literal: true

class TaskEventHandler
  attr_reader :logger

  def initialize(opts = {})
    @logger = opts[:logger] ||= Sidekiq.logger
    @task_handlers = [opts[:task_handlers] ||= initialize_default_handlers].flatten.compact
  end

  def run_task(message_body_hash)
    task = message_body_hash.fetch(:task).to_sym
    logger.debug { "Running task: #{task}. Searching for task in: #{@task_handlers}" }

    task_handlers = resolve_task_handlers(task)

    if task_handlers.blank?
      raise UnknownTaskError, "Could not find task: #{task} in any of the available task_handlers: #{@task_handlers}"
    end

    invoke_task_handler(task_handlers.first, task, message_body_hash.fetch(:parameters, {}))
  end

  private

  def resolve_task_handlers(task)
    task_handlers = @task_handlers.select { |task_handler| task_handler.respond_to?(task) }

    task_handlers.each do |task_handler|
      logger.debug { "Found task handler: #{task_handler.class} that can handle task: #{task}" }
    end
    task_handlers
  end

  def invoke_task_handler(task_handler, task, params)
    logger.debug { "Invoking handler: #{task_handler.class}##{task} with params: #{params}" }
    task_handler.public_send(task, params)
  end

  def initialize_default_handlers
    [
      DatabaseTasks.new
      # Other tasks go here
    ]
  end
end
