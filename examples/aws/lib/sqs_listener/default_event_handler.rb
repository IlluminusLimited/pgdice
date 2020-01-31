# frozen_string_literal: true

class DefaultEventHandler
  attr_reader :logger

  def initialize(opts = {})
    @logger = opts[:logger] ||= Sidekiq.logger
    @fallthrough_event_handler = opts[:fallthrough_event_handler] ||= FallthroughEventHandler.new(logger: logger)
  end

  def handle_message(message)
    # Since 'message' is a JSON formatted string, parse the JSON and then get the values under the 'Records' key
    # When JSON parses a string it returns a Ruby Hash (just like a Java HashMap)
    records = JSON.parse(message.body)['Records']
    if records
      process_records(records, message)
    else
      # If the message body doesn't have any entries under the 'Records' key then we don't know what to do.
      @fallthrough_event_handler.call(message)
    end
  rescue StandardError => e
    # If any errors are raised processing this message then call the fallthrough because something went wrong.
    logger.error { "Caught error while handling incoming message. Calling fallthrough_event_handler. Error: #{e}" }
    @fallthrough_event_handler.call(message)
  end

  private

  def process_records(records, message)
    # Process default event
  end
end
