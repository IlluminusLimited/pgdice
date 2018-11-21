[![CircleCI](https://circleci.com/gh/IlluminusLimited/pgdice.svg?style=shield)](https://circleci.com/gh/IlluminusLimited/pgdice)
[![Coverage Status](https://coveralls.io/repos/github/IlluminusLimited/pgdice/badge.svg?branch=master)](https://coveralls.io/github/IlluminusLimited/pgdice?branch=master)
[![Maintainability](https://api.codeclimate.com/v1/badges/311e005a14749bf2f826/maintainability)](https://codeclimate.com/github/IlluminusLimited/pgdice/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/311e005a14749bf2f826/test_coverage)](https://codeclimate.com/github/IlluminusLimited/pgdice/test_coverage)
[![Gem Version](https://badge.fury.io/rb/pgdice.svg)](https://badge.fury.io/rb/pgdice)

# PgDice

PgDice is a utility for creating and maintaining partitioned database tables that builds on top of the excellent gem
 [https://github.com/ankane/pgslice](https://github.com/ankane/pgslice)
 
PgDice is intended to be used by scheduled background jobs in frameworks like [Sidekiq](https://github.com/mperham/sidekiq)
where logging and clear exception messages are crucial.


## Disclaimer

There are some features in this gem which allow you to drop database tables. 

If you choose to use this software without a __tested and working__ backup and restore strategy in place then you 
are a fool and will pay the price for your negligence. THIS SOFTWARE IS PROVIDED "AS IS",
WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED. By using this software you agree that the creator, 
maintainers and any affiliated parties CANNOT BE HELD LIABLE FOR DATA LOSS OR LOSSES OF ANY KIND.

See the [LICENSE](LICENSE) for more information.


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'pgdice'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install pgdice

## Usage

### Configuration

You must configure `PgDice` before you can use it, otherwise you won't be able to perform any manipulation actions
on tables.

This is an example config from a project using `Sidekiq` 
```ruby
require 'pgdice'
PgDice.configure do |config|
  # This defaults to STDOUT if you don't specify a logger
  config.logger_factory = proc { Sidekiq.logger }
  config.database_url = ENV['PGDICE_DATABASE_URL'] # postgresql://[user[:password]@][host][:port][/dbname][?param1=value1&...]
 
  # Set a config file or build the tables manually
  config.config_file = Rails.root.join('config', 'pgdice.yml') # If you are using rails, else provide the absolute path.
  # and/or
  config.approved_tables = PgDice::ApprovedTables.new(
    PgDice::Table.new(table_name: 'comments', past: 90, future: 7, period: 'day'),
    PgDice::Table.new(table_name: 'posts', past: 6, future: 2, period: 'month')
  )
end
```


#### Configuration Parameters

- `database_url` - Required: The postgres database url to connect to. 
  - This is required since `pgslice` requires a postgres `url`.

- `logger_factory` - Optional: A factory that will return a logger to use.
  - Defaults to `proc { Logger.new(STDOUT) }`

- `approved_tables` - Optional: (but not really) The tables to allow modification on.
  - If you want to manipulate database tables with this gem you're going to need to provide this data.
    - See the [Approved Tables Configuration](#approved-tables-configuration) section for more.

- `dry_run` - Optional: Boolean value to control whether changes are executed on the database.
  - You can set it to either `true` or `false`. 
    - `true` will make PgDice log out the commands but not execute them.

- `batch_size` - Optional: Maximum number of tables you can drop in one `drop_old_partitions` call. 
  - Defaults to 7.


#### Advanced Configuration Parameters

All of the following parameters are optional and honestly you probably will never need to mess with these.

- `pg_connection` - This is a `PG::Connection` object used for the database queries made from `pgdice`.
  - By default it will be initialized from the `database_url` if left `nil`. 
  - Keep in mind the dependency `pgslice` will still establish its own connection using the `database_url` 
  so this feature may not be very useful if you are trying to only use one connection for this utility.

 
### Approved Tables Configuration

In order to maintain the correct number of partitions over time you must configure a 
[PgDice::Table](lib/pgdice/table.rb).

An example configuration file has been provided at [config.yml](examples/config.yml) if you would rather
declare your `approved_tables` in yaml.

#### Alternative Approved Tables Configuration 

If you want to declare your [PgDice::ApprovedTables](lib/pgdice/approved_tables.rb) in your configuration
block instead, you can build them like so:

```ruby
require 'pgdice'
PgDice.configure do |config|
  config.approved_tables = PgDice::ApprovedTables.new(
    PgDice::Table.new(table_name: 'comments', # Table name for the (un)partitioned table
                      past: 90, # The minimum number of tables to keep before dropping older tables.
                      future: 7, # Number of future tables to always have.
                      period: 'day', # day, month, year
                      column_name: 'created_at', # Whatever column you'd like to partition on.
                      schema: 'public'), # Schema that this table belongs to.
    PgDice::Table.new(table_name: 'posts') # Minimum configuration (90 past, 7 future, 'day' period).
  )
end
```

It is possible to use both the configuration block and a file if you so choose. 
The block will take precedence over the values in the file.
 
### Converting existing tables to partitioned tables

__This should only be used on smallish tables and ONLY after you have tested it on a non-production copy of your 
production database.__
In fact, you should just not do this in production. Schedule downtime or something and run it a few times on
a copy of your database. Then practice restoring your database some more.


This command will convert an existing table into 61 partitioned tables (30 past, 30 future, and one for today).

For more information on what's going on in the background see 
[https://github.com/ankane/pgslice](https://github.com/ankane/pgslice)


```ruby
PgDice.partition_helper.partition_table('comments')
```

If you mess up (again you shouldn't use this in production). These two methods are useful for writing tests
that work with partitions.

#### Notes on partition_table

- You can override values configured in the `PgDice::Table` by passing them in as a hash. 
  - For example if you wanted to create `30` future tables instead of the configured `7` for the `comments` table
  you could pass in `future: 30`.

```ruby
PgDice.partition_helper.undo_partitioning!('comments')
```

#### Notes on `partition_table`

- In `partition_helper` there are versions of the methods that will throw exceptions (ending in `!`) and others 
that will return a truthy value or `false` if there is a failure.

- `period` can be set to one of these values: `:day`, `:month`, `:year`


### Maintaining partitioned tables

#### Adding more tables

If you have existing tables that need to periodically have more tables added you can run:

```ruby
PgDice.partition_manager.add_new_partitions('comments')
```

##### Notes on `add_new_partitions`

- The above command would add `7` new tables and their associated indexes all based on the `period` that the
partitioned table was defined with.
 - The example `comments` table we have been using was configured to always keep `7` future partitions above.


#### Listing droppable partitions

Sometimes you just want to know what's out there and if there are tables ready to be dropped.

To list all eligible tables for dropping you can run:
```ruby
PgDice.partition_manager.list_droppable_partitions('comments')
```

##### Notes on `list_droppable_partitions`

- This method uses the `past` value from the `PgDice::Table` to determine which tables are eligible for dropping.


#### Dropping old tables

_Dropping tables is irreversible! Do this at your own risk!!_

If you want to drop old tables (after backing them up of course) you can run:

```ruby
PgDice.partition_manager.drop_old_partitions(table_name: 'comments')
```

##### Notes on `drop_old_partitions`

- The above example command would drop partitions that exceed the configured `past` table count
for the `PgDice::Table`. 
  - The example `comments` table has been configured with `past: 90` tables. 
  So if there were 100 tables older than `today` it would drop up to `batch_size` tables.
  

#### Validating everything is still working

If you've got background jobs creating and dropping tables you're going to want to 
ensure they are actually working correctly. 

To validate that your expected number of tables exist, you can run:
```ruby
PgDice.validation.assert_tables('comments', future: 7, past: 90)
```

An [InsufficientTablesError](lib/pgdice.rb) will be raised if any conditions are not met.

This will check that the table 30 days from now exists and that there is 
still a table from 90 days ago. The above example assumes the table was partitioned
by day.


## FAQ

1. How do I get a postgres url if I'm running in Rails?
```ruby
 def build_postgres_url
  config = Rails.configuration.database_configuration
  host = config[Rails.env]["host"]
  database = config[Rails.env]["database"]
  username = config[Rails.env]["username"]
  password = config[Rails.env]["password"]

  "postgres://#{username}:#{password}@#{host}/#{database}"
end
```

1. I'm seeing off-by-one errors for my `validation.assert_tables` calls?
    - You should make sure your database is configured to use `UTC`.
    [https://www.postgresql.org/docs/10/datatype-datetime.html](https://www.postgresql.org/docs/10/datatype-datetime.html) 

## Planned Features

1. Full `PG::Connection` support (no more database URLs).
1. Custom schema support for all operations. Defaults to `public` currently.
1. Non time-range based partitioning.


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. 
You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.


### Running tests

You're going to need to have postgres 10 or greater installed.

Run the following commands from your terminal. Don't run these on anything but a development machine.

1. `psql postgres -c "create role pgdice with createdb superuser login password 'password';"`
1. `createdb pgdice_test`
1. Now you can run the tests via `guard` or `rake test`


## Contributing

Bug reports and pull requests are welcome on GitHub at 
[https://github.com/IlluminusLimited/pgdice](https://github.com/IlluminusLimited/pgdice). This project is intended 
to be a safe, welcoming space for collaboration, and contributors are expected to adhere to
 the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).


## Code of Conduct

Everyone interacting in the Pgdice project’s codebases, issue trackers, chat rooms and mailing lists is expected 
to follow the [code of conduct](https://github.com/IlluminusLimited/pgdice/blob/master/CODE_OF_CONDUCT.md).
