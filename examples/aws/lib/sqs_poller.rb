# frozen_string_literal: true

require 'aws-sdk-sqs'

class SqsPoller
  attr_reader :logger, :queue_url

  MAX_RETRIES ||= 3
  DEFAULT_WAIT_TIME ||= 5

  def initialize(opts = {})
    @logger = opts[:logger] ||= ActiveSupport::TaggedLogging.new(Logger.new(ENV['POLL_SQS_LOG_OUTPUT'] || STDOUT))
    @max_retries = opts[:max_retries] ||= MAX_RETRIES
    @sleep_seconds = opts[:sleep_seconds] ||= DEFAULT_WAIT_TIME
    @error_sleep_seconds = opts[:error_sleep_seconds] ||= @sleep_seconds * 2
    @sqs_listener = opts[:sqs_listener] ||= SqsListener.new(logger: logger)
  end

  def poll(iterations = Float::INFINITY)
    logger.info { "Starting loop to #{iterations}, press Ctrl-C to exit" }

    retries = 0
    i = 0

    while i < iterations
      begin
        i += 1
        execute_loop
      rescue StandardError => e
        if retries < MAX_RETRIES
          retries = handle_retry(retries, e)
          retry
        else
          die(e)
        end
      rescue Exception => e
        die(e)
      end
    end
  end

  private

  def execute_loop
    @sqs_listener.call
    sleep @sleep_seconds
  end

  def handle_retry(retries, error)
    logger.error do
      "Polling loop encountered an error. Will retry in #{@error_sleep_seconds} seconds. "\
        "Error: #{error}. Retries: #{retries}"
    end
    retries += 1

    # Handle error with error tracking service
    # @error_handler.call(error)

    sleep @error_sleep_seconds
    retries
  end

  def die(error)
    logger.fatal { "Polling loop is stopping due to exception: #{error}" }
    raise error
  end
end
