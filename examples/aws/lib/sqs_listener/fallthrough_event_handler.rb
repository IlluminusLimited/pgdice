# frozen_string_literal: true

class FallthroughEventHandler
  attr_reader :logger

  def initialize(opts = {})
    @logger = opts[:logger] ||= Sidekiq.logger
    @sqs_message_deleter = opts[:sqs_message_deleter] ||= SqsMessageDeleter.new(logger: logger)
  end

  def call(message)
    logger.warn do
      "Received sqs message we don't know how to process. Message: #{message}"
    end

    @sqs_message_deleter.call(message.receipt_handle)
  end
end
