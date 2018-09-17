# Change Log
All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).

## [v0.1.1] : 2018-09-17
### Changelog added

### Added
- Support for overriding configuration parameters 
    - [DatabaseConnection](lib/pgdice/database_connection.rb) now accepts an opts hash
    - [PartitionHelper](lib/pgdice/partition_helper.rb) now accepts an opts hash
    - [PartitionManager](lib/pgdice/partition_manager.rb) now accepts an opts hash
    - [PgSliceManager](lib/pgdice/pg_slice_manager.rb) now accepts an opts hash
    - [Validation](lib/pgdice/validation.rb) now accepts an opts hash
