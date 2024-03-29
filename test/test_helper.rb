# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'simplecov'
require 'minitest/autorun'
require 'minitest/ci'

root_dir = Pathname.new('..').expand_path(File.dirname(__FILE__))

Minitest::Ci.report_dir = root_dir.join('tmp', 'test-results')

SimpleCov.coverage_dir(root_dir.join('tmp', 'coverage', 'pgdice'))

SimpleCov.start do
  add_group('pgdice', 'lib/pgdice')
  add_filter %r{^/test/}
end

require 'pgdice'

module Minitest
  class Test
    @sql = <<~SQL
      SET client_min_messages = warning;
      SET TIME ZONE 'UTC';
      DROP TABLE IF EXISTS "posts_intermediate" CASCADE;
      DROP TABLE IF EXISTS "posts" CASCADE;
      DROP TABLE IF EXISTS "posts_retired" CASCADE;
      DROP TABLE IF EXISTS "comments_intermediate" CASCADE;
      DROP TABLE IF EXISTS "comments" CASCADE;
      DROP TABLE IF EXISTS "comments_retired" CASCADE;
      DROP FUNCTION IF EXISTS "comments_insert_trigger"();
      DROP TABLE IF EXISTS "users" CASCADE;
      CREATE TABLE "users" (
       "id" SERIAL PRIMARY KEY
      );
      CREATE TABLE "comments" (
        "id" SERIAL PRIMARY KEY,
        "user_id" INTEGER,
        "created_at" timestamp,
        "created_on" date,
        CONSTRAINT "foreign_key_1" FOREIGN KEY ("user_id") REFERENCES "users"("id")
      );
      CREATE INDEX ON "comments" ("created_at");
      INSERT INTO "comments" ("created_at", "created_on")
        SELECT NOW(), NOW() FROM generate_series(1, 10000) n;

      CREATE TABLE "posts" (
        "id" SERIAL PRIMARY KEY,
        "user_id" INTEGER,
        "created_at" timestamp,
        "created_on" date,
        CONSTRAINT "foreign_key_1" FOREIGN KEY ("user_id") REFERENCES "users"("id")
      );
      CREATE INDEX ON "posts" ("created_at");
      INSERT INTO "posts" ("created_at", "created_on")
        SELECT NOW(), NOW() FROM generate_series(1, 10000) n;
    SQL

    PgDice.configure(validate_configuration: false) do |config|
      log_target = ENV['PGDICE_LOG_TARGET'] || 'pgdice.log'
      config.logger_factory = proc { Logger.new(log_target) }

      username = ENV['DATABASE_USERNAME']
      password = ENV['DATABASE_PASSWORD']
      login = ''
      login = "#{username}@" if username
      login = "#{username}:#{password}@" if password
      host = ENV['DATABASE_HOST']

      config.database_url = "postgres://#{login}#{host}/pgdice_test"
      config.approved_tables = PgDice::ApprovedTables.new(
        PgDice::Table.new(table_name: 'comments', past: 1, future: 0),
        PgDice::Table.new(table_name: 'posts', past: 10, future: 0)
      )
      config.config_file_loader = PgDice::ConfigurationFileLoader.new(config, file_loaded: true)
    end
    PgDice.configuration.logger.info { 'Starting tests' }

    PgDice.configuration.database_connection.execute(@sql)

    def logger
      @logger ||= PgDice.configuration.logger
    end

    def table_name
      @table_name ||= 'comments'
    end

    def partition_helper
      @partition_helper ||= PgDice.partition_helper
    end

    def assert_invalid_config(&block)
      assert_raises(PgDice::InvalidConfigurationError) { block.yield }
    end

    def assert_future_tables_error(&block)
      assert_raises(PgDice::InsufficientFutureTablesError) { block.yield }
    end

    def assert_past_tables_error(&block)
      assert_raises(PgDice::InsufficientPastTablesError) { block.yield }
    end

    def today
      Time.now.utc
    end

    def tomorrow
      today + (1 * 24 * 60 * 60)
    end

    def yesterday
      today - (1 * 24 * 60 * 60)
    end
  end
end
