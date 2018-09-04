# Pgdice

PgDice is a utility that builds on top of the excellent gem
 [https://github.com/ankane/pgslice](https://github.com/ankane/pgslice)
 
PgDice  is intended to be used by scheduled background jobs in frameworks like [Sidekiq](https://github.com/mperham/sidekiq)
where logging and clear exception messages are crucial.

# Disclaimer

There are some features in this gem which allow you to drop database tables. 

If you choose to use these features without a __tested__ backup strategy in place then you 
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
  config.database_url = ENV['DATABASE_URL'] # postgresql://[user[:password]@][host][:port][/dbname][?param1=value1&...]
  config.approved_tables = ENV['PGDICE_APPROVED_TABLES'] # Comma separated values: 'comments,posts'
end
```

### Converting existing tables to partitioned tables

__This should only be used on small tables and ONLY after you have tested it on a non-production copy of your production database__

```ruby
PgDice.
```
## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at [https://github.com/IlluminusLimited/pgdice](https://github.com/IlluminusLimited/pgdice). This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Pgdice project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/IlluminusLimited/pgdice/blob/master/CODE_OF_CONDUCT.md).
