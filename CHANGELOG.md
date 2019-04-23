# Change Log
All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).

## [v0.4.3] : 2019-04-23
### Changes
  - Fix #31 where the new connection retry code was eagerly initializing the logger


## [v0.4.2] : 2019-04-22
### Changes
  - Fix #19 where PgDice wouldn't recover from a broken PG::Connection 
  by adding new retry behavior


## [v0.4.1] : 2019-03-21
### Changes
  - Fix bug where partitioning by months would break when the month was < 10


## [v0.4.0] : 2018-12-06
### Changes
  - Add `only:` option to `assert_tables` so users can assert on only `past`
  or `future` tables if they wish.
  - Fix #21 by adding documentation on how to migrate existing data from 
  unpartitioned tables


## [v0.3.3] : 2018-11-30
### Changes
  - Do not eagerly initialize the `pg_connection` as this can cause some normal
  `rails` tasks to break (like database dropping). #24


## [v0.3.2] : 2018-11-29
### Changes
  - Fix behavior of `undo_partitioning` to drop intermediate tables if `partition_table`
  failed before swapping tables.


## [v0.3.1] : 2018-10-22
### Changes
  - Bump up `approved_tables` to `PgDice` module.


## [v0.3.0] : 2018-10-21
### Changes
  - Delegate methods from the management classes onto the `PgDice` module itself.
    - This means the api for this project is significantly more simple to use.


## [v0.2.1] : 2018-10-21
### Changes
  - Renamed `PartitionManager.list_batched_droppable_partitions` to
  `PartitionManager.list_droppable_partitions_by_batch_size`
  - Readme updated
  

## [v0.2.0] : 2018-10-21
 - Changelog added
