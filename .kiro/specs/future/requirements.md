**Source/Sink Implementations** (separate gems):
- `active_data_flow-rafka` - Kafka-compatible API backed by Redis streams
- `active_data_flow-active_record` - Rails RDBMS integration
- `active_data_flow-iceberg` - Apache Iceberg table format support
- `active_data_flow-file` - Local and remote file system support

**DataFlow Runtime Implementations** (separate gems):
- `active_data_flow-rails_heartbeat_job` - Runs DataFlows as ActiveJob background jobs
- `active_data_flow-rails_heartbeat_job` - Runs DataFlows as ActiveJob background jobs
- `active_data_flow-aws_lambda` - Runs DataFlows as AWS Lambda functions
- `active_data_flow-flink` - Runs DataFlows in Apache Flink runtime