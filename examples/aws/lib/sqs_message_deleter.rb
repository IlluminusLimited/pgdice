# frozen_string_literal: true

require 'aws-sdk-sqs'

class SqsMessageDeleter
  attr_reader :logger

  def initialize(opts = {})
    @logger = opts[:logger] ||= Sidekiq.logger
    @queue_url = opts[:queue_url] ||= ENV['SqsQueueUrl']
    @sqs_client = opts[:sqs_client] ||= Aws::SQS::Client.new
    @skip_delete_predicate = opts[:skip_delete_predicate] ||= proc do
      Rails.env != 'production' || ENV['READ_ONLY_SQS'].to_s == 'true'
    end
  end

  def call(sqs_message_receipt_handle)
    if @skip_delete_predicate.call
      logger.info { "Not destroying sqs message because environment is not prod or READ_ONLY_SQS was set to 'true'" }
      return false
    end

    logger.debug { "Destroying sqs message with handle: #{sqs_message_receipt_handle}" }

    response = @sqs_client.delete_message(queue_url: @queue_url, receipt_handle: sqs_message_receipt_handle)
    unless response.successful?
      raise "Attempt to delete SQS message: #{sqs_message_receipt_handle} was not successful. Response: #{response}"
    end

    true
  end
end
