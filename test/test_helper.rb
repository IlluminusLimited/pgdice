# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'pgdice'
require 'minitest/autorun'

module Minitest
  class Test
    @sql = <<~SQL
      DROP TABLE IF EXISTS "Comments_intermediate" CASCADE;
      DROP TABLE IF EXISTS "Comments" CASCADE;
      DROP TABLE IF EXISTS "Comments_retired" CASCADE;
      DROP FUNCTION IF EXISTS "Comments_insert_trigger"();
      DROP TABLE IF EXISTS "Users" CASCADE;
        CREATE TABLE "Users" (
         "Id" SERIAL PRIMARY KEY
        );
         CREATE TABLE "Comments" (
          "Id" SERIAL PRIMARY KEY,
          "UserId" INTEGER,
          "createdAt" timestamp,
          "createdAtTz" timestamptz,
          "createdOn" date,
          CONSTRAINT "foreign_key_1" FOREIGN KEY ("UserId") REFERENCES "Users"("Id")
        );
        CREATE INDEX ON "Comments" ("createdAt");
        INSERT INTO "Comments" ("createdAt", "createdAtTz", "createdOn")
                SELECT NOW(), NOW(), NOW() FROM generate_series(1, 10000) n;
    SQL
    PgDice.configure do |config|
      config.database_url = 'postgres:///pgdice_test'
    end
    PgDice.configuration.database_connection.exec(@sql)
  end
end
