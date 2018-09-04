# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'pgdice'
require 'minitest/autorun'

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
      config.database_url = 'postgres:///pgdice_test'
      config.approved_tables = ['comments']
    end
    PgDice.configuration.database_connection.execute(@sql)

    def table_name
      @table_name ||= 'comments'
    end

    def preparation_helper
      @preparation_helper ||= PgDice::PreparationHelper.new(PgDice.configuration)
    end
  end
end
