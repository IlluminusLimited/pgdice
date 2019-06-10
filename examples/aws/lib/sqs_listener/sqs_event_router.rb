# frozen_string_literal: true

# Responsible for routing incoming SQS events to the correct handler
class SqsEventRouter
  attr_reader :logger

  def initialize(opts = {})
    @logger = opts[:logger] ||= Sidekiq.logger
    @task_event_handler = opts[:task_event_handler] ||= TaskEventHandler.new(logger: logger)
    @default_event_handler = opts[:default_event_handler] ||= DefaultEventHandler.new(logger: logger)
    @sqs_message_deleter = opts[:sqs_message_deleter] ||= SqsMessageDeleter.new(logger: logger)
  end

  # Handles incoming sqs event, looking for a field of 'event_type'
  # See scheduled_events.json for details on how to create task events from cloudwatch
  def handle_message(message)
    message_body = JSON.parse(message.body).with_indifferent_access
    event_type = message_body[:event_type]

    logger.tagged(message.receipt_handle) do
      logger.debug { "The received message was: #{message}" }

      case event_type
      when 'task'
        @task_event_handler.run_task(message_body)
        @sqs_message_deleter.call(message.receipt_handle)
      else
        @default_event_handler.handle_message(message)
      end
    end
  end
end
