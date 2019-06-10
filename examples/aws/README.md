# How can I use PgDice in production?

This collection of files is how I use PgDice in production. I'll describe the architecture here so you'll have a place
to start.

1. `tasks/poll_sqs.rake` is run using some sort of process manager like systemd on the ec2 instance. I like to run
the poll_sqs stuff on my Sidekiq instances because they are the ones who eventually handle the work anyway.

1. `lib/sqs_poller.rb` is used to handle the looping logic for the rake task. It invokes `lib/sqs_listener.rb` for each 
iteration.

1. `lib/sqs_listener.rb` calls AWS SQS to receive messages and then passes each one into the `lib/sqs_listener/sqs_event_router.rb` 
to be routed to the correct message handler.

1. Inside `lib/sqs_listener/sqs_event_router.rb` the message is parsed and passed through a case statement. 
This could be abstracted better but for now if the message has a field of `event_type` and a value of `"task"` then
the router will send it off to the `TaskEventHandler` which in this case is 
`lib/sqs_listener/typed_event_handler/task_event_handler.rb`

1. In the `TaskEventHandler` the task is sent to a handler which responds to the task specified in the message body field `task`.

1. The handler for the task (in this case, `DatabaseTasks`) handles the parameters for invoking the Sidekiq worker: `PgDiceWorker`

1. Finally, the `PgDiceWorker` is called and handles invoking `PgDice` based on the parameters passed in.


Hopefully that wasn't too confusing. There's a lot of steps in here because the system that uses PgDice handles lots
of different types of SQS events and needs to be as resilient as possible.