# ActiveDataFlow JSON-RPC Sink Connector

A sink connector for ActiveDataFlow that sends data via JSON-RPC client. This connector implements a Jimson client that sends outgoing data to a remote JSON-RPC server.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'active_data_flow-connector-sink-json_rpc'
```

And then execute:

```bash
bundle install
```

## Features

The JSON-RPC sink connector provides a client that sends data via JSON-RPC calls to a remote server. Key features include:

- **Flexible Writing**: Send records individually or in batches
- **Automatic Buffering**: Buffer records and flush when batch size is reached
- **Error Handling**: Graceful error handling with detailed logging
- **Connection Testing**: Test server connectivity before sending data
- **Health Monitoring**: Check remote server health status
- **Thread Safety**: Thread-safe buffering for concurrent writes

## Usage

### Basic Usage

```ruby
require 'active_data_flow-connector-sink-json_rpc'

# Create a JSON-RPC sink
sink = ActiveDataFlow::Connector::Sink::JsonRpcSink.new(
  url: 'http://localhost:8999',
  batch_size: 100
)

# Test connection
if sink.test_connection
  # Write a single record
  sink.write({ name: 'John Doe', email: 'john@example.com' })
  
  # Write multiple records
  records = [
    { name: 'Alice', email: 'alice@example.com' },
    { name: 'Bob', email: 'bob@example.com' }
  ]
  sink.write_batch(records)
  
  # Clean up
  sink.close
end
```

### Buffered Writing

```ruby
# Create a sink with buffering
sink = ActiveDataFlow::Connector::Sink::JsonRpcSink.new(
  url: 'http://localhost:8999',
  batch_size: 100
)

# Buffer records (automatically flushes when batch_size is reached)
100.times do |i|
  sink.buffer_write({ id: i, name: "User #{i}" })
end

# Manually flush remaining records
sink.flush

# Close (also flushes)
sink.close
```

### In a Data Flow

```ruby
# Create a source (e.g., ActiveRecord)
source = ActiveDataFlow::Connector::Source::ActiveRecordSource.new(
  scope: User.active,
  scope_params: []
)

# Create the JSON-RPC sink
sink = ActiveDataFlow::Connector::Sink::JsonRpcSink.new(
  url: 'http://remote-server.com:8999',
  batch_size: 100
)

# Create the data flow
runtime = ActiveDataFlow::Runtime::Heartbeat.new(interval: 60)

ActiveDataFlow::DataFlow.create!(
  name: "database_to_json_rpc",
  source: source,
  sink: sink,
  runtime: runtime
)
```

### With Custom Client Options

```ruby
# Configure client with custom options
sink = ActiveDataFlow::Connector::Sink::JsonRpcSink.new(
  url: 'http://localhost:8999',
  batch_size: 100,
  client_options: {
    timeout: 30,
    # Add other Jimson::Client options here
  }
)
```

## Configuration Options

### Initialization Parameters

- **url** (String, required): The JSON-RPC server URL
- **batch_size** (Integer): Number of records to buffer before flushing (default: `100`)
- **client_options** (Hash): Additional options for Jimson::Client (default: `{}`)

## API Reference

### Instance Methods

#### `#write(record)`
Sends a single record to the JSON-RPC server immediately.

**Parameters:**
- `record` (Hash): The record to send

**Returns:** Hash with response status

#### `#write_batch(records)`
Sends multiple records to the JSON-RPC server in a single batch.

**Parameters:**
- `records` (Array<Hash>): The records to send

**Returns:** Hash with response status

#### `#buffer_write(record)`
Buffers a record and automatically flushes when batch size is reached.

**Parameters:**
- `record` (Hash): The record to buffer

**Returns:** Hash with response status if flushed, nil otherwise

#### `#flush`
Flushes all buffered records to the server.

**Returns:** Hash with response status or nil if buffer was empty

#### `#close`
Flushes remaining records and cleans up resources.

#### `#test_connection`
Tests connectivity to the JSON-RPC server.

**Returns:** Boolean indicating connection success

#### `#health_check`
Retrieves health status from the JSON-RPC server.

**Returns:** Hash with health status

#### `#buffer_size`
Returns the current number of buffered records.

**Returns:** Integer

## Error Handling

The sink connector includes comprehensive error handling:

- **Network Errors**: Connection failures are caught and logged
- **RPC Errors**: JSON-RPC errors are caught and logged
- **Validation Errors**: Invalid responses are handled gracefully

Errors are logged to Rails logger if available, otherwise printed to stdout. The connector continues operation after errors, allowing for resilient data pipelines.

## Thread Safety

The sink connector uses a mutex to ensure thread-safe access to the internal buffer. This allows multiple threads to safely call `buffer_write` concurrently.

## Architecture

The JSON-RPC sink connector operates as follows:

1. **Client Initialization**: Creates a Jimson client wrapper configured with the server URL
2. **Record Buffering**: Optionally buffers records in memory until batch size is reached
3. **Batch Transmission**: Sends records to the remote server via JSON-RPC calls
4. **Error Recovery**: Handles errors gracefully and continues processing

This architecture provides efficient batch transmission while maintaining the flexibility to send individual records when needed.

## Integration with Source Connector

The sink connector is designed to work seamlessly with the source connector:

```ruby
# On Server A: Receive data via JSON-RPC
source = ActiveDataFlow::Connector::Source::JsonRpcSource.new(
  host: '0.0.0.0',
  port: 8999
)

# On Server B: Send data via JSON-RPC
sink = ActiveDataFlow::Connector::Sink::JsonRpcSink.new(
  url: 'http://server-a.com:8999',
  batch_size: 100
)

# Server B sends data to Server A
sink.write({ data: 'example' })
```

## Performance Considerations

The connector provides several features for optimizing performance:

- **Batching**: Use `write_batch` or `buffer_write` for better throughput
- **Batch Size**: Tune `batch_size` based on network latency and record size
- **Connection Pooling**: Jimson client maintains persistent connections

For high-throughput scenarios, use buffered writes with an appropriate batch size (typically 100-1000 records).

## Development

After checking out the repo, run:

```bash
bundle install
```

To run tests:

```bash
bundle exec rspec
```

To run Cucumber tests:

```bash
bundle exec cucumber
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/magenticmarketactualskill/active_data_flow-connector-sink-json_rpc.

## License

The gem is available as open source under the terms of the MIT License.
