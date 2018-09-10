[![CircleCI](https://circleci.com/gh/IlluminusLimited/pgdice.svg?style=shield)](https://circleci.com/gh/IlluminusLimited/pgdice)
[![Coverage Status](https://coveralls.io/repos/github/IlluminusLimited/pgdice/badge.svg?branch=master)](https://coveralls.io/github/IlluminusLimited/pgdice?branch=master)
# PgDice

PgDice is a utility that builds on top of the excellent gem
 [https://github.com/ankane/pgslice](https://github.com/ankane/pgslice)
 
PgDice is intended to be used by scheduled background jobs in frameworks like [Sidekiq](https://github.com/mperham/sidekiq)
where logging and clear exception messages are crucial.

## Disclaimer

There are some features in this gem which allow you to drop database tables. 

If you choose to use this software without a __tested and working__ backup and restore strategy in place then you 
are a fool and will pay the price for your negligence. This software comes with no warranty 
or any guarantees, implied or otherwise. By using this software you agree that the creator, 
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
  config.logger = Sidekiq.logger # This defaults to STDOUT if you don't specify a logger
  config.database_url = ENV['PGDICE_DATABASE_URL'] # postgresql://[user[:password]@][host][:port][/dbname][?param1=value1&...]
  config.approved_tables = ENV['PGDICE_APPROVED_TABLES'] # Comma separated values: 'comments,posts'
end
```

#### Configuration Parameters

`logger` Optional: The logger to use. If you don't set this it defaults to STDOUT.

`database_url` The postgres database url to connect to. This is required since `pgslice` is used to accomplish some tasks
and it only takes a `url` currently.

`approved_tables` This one is important. If you want to manipulate database tables with this gem you're going to
need to add the base table name to this string of comma-separated values.

`additional_validators` Optional: This can accept an array of `proc` or `lambda` type predicates. 
Each predicate will be passed the `params` hash and a `logger`. These predicates are called before doing things like
dropping tables and adding tables. 

`dry_run` Optional: You can set it to either `true` or `false`. This will make PgDice print the commands but not 
execute them.

`older_than` Optional: Time object used to scope the queries on droppable tables. Defaults to 90 days ago.

`table_drop_batch_size` Optional: Maximum number of tables you can drop in one query. Defaults to 7.

#### Advanced Configuration Parameters

`table_dropper` This defaults to [TableDropper](lib/pgdice/table_dropper.rb) which has a `lambda`-like interface. 
An example use-case would be calling out to your backup system to confirm the table is backed up.
This mechanism will be passed the `table_to_drop` and a `logger`.

`pg_connection` This is a `PG::Connection` object used for the database queries made from `pgdice`.
 By default it will be initialized from the `database_url` if left `nil`. Keep in mind the dependency 
 `pgslice` will still establish its own connection using the `database_url` so this feature may not be very
 useful if you are trying to only use one connection for this utility.
 
 `database_connection` You can supply your own [DatabaseConnection](lib/pgdice/database_connection.rb) if you like.
 I'm not sure why you would do this.
 
 `pg_slice_manager` This is an internal wrapper around `pgslice`. [PgSliceManager](lib/pgdice/pg_slice_manager.rb)
  This configuration lets you provide your own if you wish. I'm not sure why you would do this.
 
 `partition_manager` You can supply your own [PartitionManager](lib/pgdice/partition_manager.rb) if you like.
  I'm not sure why you would do this.
  
 `partition_helper` You can supply your own [PartitionHelper](lib/pgdice/partition_helper.rb) if you like.
  I'm not sure why you would do this.
 
### Converting existing tables to partitioned tables

__This should only be used on smallish tables and ONLY after you have tested it on a non-production copy of your 
production database.__
In fact, you should just not do this in production. Schedule downtime or something and run it a few times on
a copy of your database. Then practice restoring your database some more.


This command will convert an existing table into 61 partitioned tables (30 past, 30 future, and one for today).

For more information on what's going on in the background see 
[https://github.com/ankane/pgslice](https://github.com/ankane/pgslice)


```ruby
PgDice.partition_helper.partition_table!(table_name: 'comments', 
                                            past: 30, 
                                            future: 30, 
                                            column_name: 'created_at', 
                                            period: 'day')
```

If you mess up (again you shouldn't use this in production). These two methods are useful for writing tests
that work with partitions.

```ruby
PgDice.partition_helper.undo_partitioning!(table_name: 'comments')
```

In `partition_helper` there are versions of the methods that will throw exceptions (ending in `!`) and others 
that will return a truthy value or `false` if there is a failure.

### Maintaining partitioned tables

#### Adding more tables

If you have existing tables that need to periodically have more tables added you can run:

```ruby
PgDice.partition_manager.add_new_partitions(table_name: 'comments', future: 30)
```

The above command would add 30 new tables and their associated indexes all based on the `period` that the
partitioned table was defined with.


#### Listing old tables

Sometimes you just want to know what's out there and if there are tables ready to be dropped.

To list all eligible tables for dropping you can run:
```ruby
PgDice.partition_manager.list_old_partitions(table_name: 'comments', older_than: Time.now.utc - 90*24*60*60)
```

If you have `active_support` you could do:
```ruby
PgDice.partition_manager.list_old_partitions(table_name: 'comments', older_than: 90.days.ago)
```

Technically `older_than` is optional and defaults to `90 days` (see the configuration section).
It is recommended that you pass it in to be explicit, but you can rely on the configuration 
mechanism if you so choose.


#### Dropping old tables

_Dropping tables is irreversible! Do this at your own risk!!_

If you want to drop old tables (after backing them up of course) you can run:

```ruby
PgDice.partition_manager.drop_old_partitions(table_name: 'comments', older_than: Time.now.utc - 90*24*60*60)
```

If you have `active_support` you could do:
```ruby
PgDice.partition_manager.drop_old_partitions(table_name: 'comments', older_than: 90.days.ago)
```

This command would drop old partitions that are older than `90` days.

Technically `older_than` is optional and defaults to `90 days` (see the configuration section).
It is recommended that you pass it in to be explicit, but you can rely on the configuration 
mechanism if you so choose.

Another good reason to pass in the `older_than` parameter is if you are managing tables that
are partiioned by different schemes or have different use-cases 
e.g. daily vs yearly partitioned tables.

#### Validating everything is still working

If you've got background jobs creating and dropping tables you're going to want to 
ensure they are actually doing their jobs correctly. 

To validate that your expected number of tables exist, you can run:
```ruby
PgDice.validation.assert_tables(table_name: 'comments', future: 30, past: 90)
```

An [InsufficientTablesError](lib/pgdice.rb) will be raised if any conditions are not met.

This will check that the table 30 days from now exists and that there is 
still a table from 90 days ago. The above example assumes the table was partitioned
by day.

## Planned Features

1. Full `PG::Connection` support (no more database URLs).
2. Non time-range based partitioning.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. 
You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the 
version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version,
 push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).


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
