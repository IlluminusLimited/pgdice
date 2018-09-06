# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'simplecov'
require 'coveralls'
require 'minitest/autorun'
require 'minitest/ci'
Coveralls.wear!

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
    SQL
    PgDice.configure do |config|
      log_target = ENV['PGDICE_LOG_TARGET'] || 'pgdice.log'
      config.logger = Logger.new(log_target)

      username = ENV['DATABASE_USERNAME']
      password = ENV['DATABASE_PASSWORD']
      login = ''
      login = "#{username}@" if username
      login = "#{username}:#{password}@" if password
      host = ENV['DATABASE_HOST']

      config.database_url = "postgres://#{login}#{host}/pgdice_test"
      config.approved_tables = ['comments']
    end
    PgDice.configuration.database_connection.execute(@sql)

    def table_name
      @table_name ||= 'comments'
    end

    def partition_helper
      @partition_helper ||= PgDice.partition_helper
    end

    def assert_invalid_config(&block)
      assert_raises(PgDice::InvalidConfigurationError) { block.yield }
    end
  end
end
