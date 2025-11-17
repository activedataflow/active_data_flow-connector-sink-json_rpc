# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.1] - 2024-11-14

### Added
- ActiveRecord source connector for reading records from ActiveRecord models
- ActiveRecord sink connector for writing records to ActiveRecord models
- Support for batch processing with configurable batch sizes
- Query building with where, order, limit, select, and includes clauses
- Upsert support with configurable unique_by and update_only options
- Transaction support for batch writes
- Readonly mode for source queries
- Skip validations option for sink writes

### Changed
- Initial release

[0.1.1]: https://github.com/magenticmarketactualskill/active_dataflow-connector-active_record/releases/tag/v0.1.1
