# frozen_string_literal: true

module PgDice
  # LogHelper provides a convenient wrapper block to log out the duration of an operation
  module LogHelper
    class << self
      # If you want to pass the the result of your block into the message you can use '{}' and it will be
      # substituted with the result of your block.
      def log_duration(message, logger, options = {})
        logger.error { 'log_duration called without a block. Cannot time the duration of nothing.' } unless block_given?
        time_start = Time.now.utc
        result = yield
        time_end = Time.now.utc

        formatted_message = format_message(time_end, time_start, message, result)
        logger.public_send(options[:log_level] || :debug) { formatted_message }
      end

      private

      def format_message(time_end, time_start, message, result)
        message = message.sub(/{}/, result.to_s)
        "#{message} took: #{format('%.02f', (time_end - time_start))} seconds."
      end
    end
  end
end
