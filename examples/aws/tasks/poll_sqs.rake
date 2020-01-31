# frozen_string_literal: true

# You can set READ_ONLY_SQS=true if you don't want to delete messages

desc 'Poll SQS for any new test executions'
task poll_sqs: :environment do
  SqsPoller.new.poll
end
