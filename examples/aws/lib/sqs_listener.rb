# frozen_string_literal: true

require 'aws-sdk-sqs'

# READ_ONLY_SQS can be set to ensure we don't delete good messages
class SqsListener
  DEFAULT_VISIBILITY_TIMEOUT ||= 600
  attr_reader :logger, :queue_url, :visibility_timeout

  def initialize(opts = {})
    @logger = opts[:logger] ||= Sidekiq.logger
    @queue_url = opts[:queue_url] ||= ENV['SqsQueueUrl']
    @sqs_client = opts[:sqs_client] ||= Aws::SQS::Client.new
    @sqs_event_router = opts[:sqs_event_router] ||= SqsEventRouter.new(logger: logger)
    increase_timeout_resolver = opts[:increase_timeout_resolver] ||= -> { ENV['READ_ONLY_SQS'].to_s == 'true' }
    @visibility_timeout = calculate_visibility_timeout(increase_timeout_resolver.call)

    logger.debug { "Running in environment: #{ENV['RAILS_ENV']} and using sqs queue: #{queue_url}" }
  end

  # http://docs.aws.amazon.com/sdk-for-ruby/v3/developer-guide/sqs-example-get-messages-with-long-polling.html
  def call
    # This uses long polling to retrieve sqs events so we can process them
    response = @sqs_client.receive_message(queue_url: queue_url,
                                           max_number_of_messages: 10,
                                           wait_time_seconds: 20,
                                           visibility_timeout: visibility_timeout)

    if response.messages&.size&.positive?
      logger.debug { "The number of messages received from the queue was: #{response.messages&.size}" }
    end

    # Iterate over all the messages in the response (Response is a Struct which acts like an object with methods)
    response.messages&.each do |message|
      @sqs_event_router.handle_message(message)
    end
  end

  private

  def calculate_visibility_timeout(increase_timeout)
    visibility_timeout = increase_timeout ? DEFAULT_VISIBILITY_TIMEOUT * 4 : DEFAULT_VISIBILITY_TIMEOUT

    logger.info { "Visibility timeout set to: #{visibility_timeout} seconds" }
    visibility_timeout
  end
end
