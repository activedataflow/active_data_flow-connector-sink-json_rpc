# Design Document

## Overview

This design implements a Rails 8 JSON-RPC demo application that demonstrates ActiveDataFlow JSON-RPC connector usage. The system consists of two Rails 8 applications: a ServerApp that receives data via ActiveDataFlow JSON-RPC source connector, and a ClientApp that sends data via ActiveDataFlow JSON-RPC sink connector. Both applications provide web interfaces for monitoring and interaction, showcasing practical ActiveDataFlow integration patterns.

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        Rails 8 JSON-RPC Demo                                │
├─────────────────────────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────┐    JSON-RPC    ┌─────────────────────────┐ │
│  │        ClientApp            │◄──────────────►│       ServerApp         │ │
│  │      (Port 3001)            │                 │      (Port 3000)        │ │
│  │                             │                 │                         │ │
│  │ ┌─────────────────────────┐ │                 │ ┌─────────────────────┐ │ │
│  │ │   ActiveDataFlow        │ │                 │ │   ActiveDataFlow    │ │ │
│  │ │      Engine             │ │                 │ │      Engine         │ │ │
│  │ └─────────────────────────┘ │                 │ └─────────────────────┘ │ │
│  │ ┌─────────────────────────┐ │                 │ ┌─────────────────────┐ │ │
│  │ │    DataFlow             │ │                 │ │    DataFlow         │ │ │
│  │ │  ActiveRecord Source    │ │                 │ │  JsonRpc Source     │ │ │
│  │ │  JsonRpc Sink           │ │                 │ │  ActiveRecord Sink  │ │ │
│  │ └─────────────────────────┘ │                 │ └─────────────────────┘ │ │
│  │ ┌─────────────────────────┐ │                 │ ┌─────────────────────┐ │ │
│  │ │   Web Interface         │ │                 │ │   Web Interface     │ │ │
│  │ │ - Create Users/Orders   │ │                 │ │ - View Received     │ │ │
│  │ │ - Monitor DataFlows     │ │                 │ │ - Monitor DataFlows │ │ │
│  │ └─────────────────────────┘ │                 │ └─────────────────────┘ │ │
│  └─────────────────────────────┘                 └─────────────────────────┘ │
├─────────────────────────────────────────────────────────────────────────────┤
│                           Technology Stack                                   │
│  • Rails 8.0 + ActiveDataFlow Engine                                        │
│  • ActiveDataFlow JSON-RPC Connectors (Jimson-based)                       │
│  • ActiveDataFlow Heartbeat Runtime                                         │
│  • SQLite3 databases (separate for each app)                               │
│  • Bootstrap 5 for web interfaces                                           │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Components and Interfaces

### 1. ServerApp (Rails 8 Application)

**Purpose**: Demonstrate ActiveDataFlow JSON-RPC source connector usage

**Port**: 3000

**Key Components**:
- ActiveDataFlow Engine integration
- JSON-RPC source connector configuration
- ActiveRecord sink for storing received data
- Web interface for monitoring received data

**DataFlow Configuration**:
```ruby
# ServerApp DataFlow
source: ActiveDataFlow::Connector::Source::JsonRpcSource.new(
  host: '0.0.0.0',
  port: 8999
)
sink: ActiveDataFlow::Connector::Sink::ActiveRecordSink.new(
  model_class: ReceivedRecord
)
runtime: ActiveDataFlow::Runtime::Heartbeat.new(interval: 30)
```

### 2. ClientApp (Rails 8 Application)

**Purpose**: Demonstrate ActiveDataFlow JSON-RPC sink connector usage

**Port**: 3001

**Key Components**:
- ActiveDataFlow Engine integration
- ActiveRecord source for reading data to send
- JSON-RPC sink connector configuration
- Web interface for creating data and monitoring sends

**DataFlow Configuration**:
```ruby
# ClientApp DataFlow
source: ActiveDataFlow::Connector::Source::ActiveRecordSource.new(
  scope: OutgoingRecord.pending
)
sink: ActiveDataFlow::Connector::Sink::JsonRpcSink.new(
  url: 'http://localhost:8999',
  batch_size: 10
)
runtime: ActiveDataFlow::Runtime::Heartbeat.new(interval: 30)
```

### 3. JSON-RPC Communication Layer

**Purpose**: Handle JSON-RPC 2.0 communication between applications

**Components**:
- **Jimson Server** (ServerApp): Embedded in JSON-RPC source connector
- **Jimson Client** (ClientApp): Embedded in JSON-RPC sink connector
- **Protocol**: JSON-RPC 2.0 with standard methods (receive_record, receive_records)

**Communication Flow**:
1. ClientApp DataFlow reads from OutgoingRecord table
2. JSON-RPC sink sends data to ServerApp JSON-RPC endpoint
3. ServerApp JSON-RPC source receives data and queues it
4. ServerApp DataFlow processes queued data and stores in ReceivedRecord table

## Data Models

### ServerApp Models

#### ReceivedRecord Model

**Purpose**: Store data received via JSON-RPC source connector

**Attributes**:
- `id` (integer, primary key): Auto-generated unique identifier
- `record_type` (string): Type of record (user, order, product)
- `source_id` (integer): Original ID from ClientApp
- `data` (json): The received record data
- `received_at` (datetime): Timestamp when record was received
- `processed_at` (datetime): Timestamp when record was processed by DataFlow
- `created_at` (datetime): Record creation timestamp
- `updated_at` (datetime): Record update timestamp

**Validations**:
- Presence of `record_type`
- Presence of `source_id`
- Presence of `data`

**Methods**:
- `self.by_type(type)`: Scope to filter by record type
- `self.recent`: Scope for recently received records
- `processed?`: Check if record has been processed

#### Database Schema (ServerApp)

```ruby
create_table :received_records do |t|
  t.string :record_type, null: false
  t.integer :source_id, null: false
  t.json :data, null: false
  t.datetime :received_at
  t.datetime :processed_at
  t.timestamps
end

add_index :received_records, :record_type
add_index :received_records, :received_at
add_index :received_records, [:record_type, :source_id]
```

### ClientApp Models

#### OutgoingRecord Model

**Purpose**: Store data to be sent via JSON-RPC sink connector

**Attributes**:
- `id` (integer, primary key): Auto-generated unique identifier
- `record_type` (string): Type of record (user, order, product)
- `data` (json): The record data to send
- `status` (string): Status (pending, sent, failed)
- `sent_at` (datetime): Timestamp when record was sent
- `error_message` (text): Error message if send failed
- `retry_count` (integer): Number of retry attempts
- `created_at` (datetime): Record creation timestamp
- `updated_at` (datetime): Record update timestamp

**Validations**:
- Presence of `record_type`
- Presence of `data`
- Inclusion of `status` in ['pending', 'sent', 'failed']

**Scopes**:
- `pending`: Records with status 'pending'
- `sent`: Records with status 'sent'
- `failed`: Records with status 'failed'

**Methods**:
- `mark_as_sent!`: Update status to 'sent' with timestamp
- `mark_as_failed!(error)`: Update status to 'failed' with error message
- `retry!`: Reset status to 'pending' and increment retry count

#### User Model (Demo Data)

**Purpose**: Demonstrate user data creation and sending

**Attributes**:
- `id` (integer, primary key)
- `name` (string): User's full name
- `email` (string): User's email address
- `age` (integer): User's age
- `created_at` (datetime)
- `updated_at` (datetime)

#### Order Model (Demo Data)

**Purpose**: Demonstrate order data creation and sending

**Attributes**:
- `id` (integer, primary key)
- `user_id` (integer): Reference to user
- `product_name` (string): Name of ordered product
- `quantity` (integer): Quantity ordered
- `price_cents` (integer): Price in cents
- `created_at` (datetime)
- `updated_at` (datetime)

#### Database Schema (ClientApp)

```ruby
create_table :outgoing_records do |t|
  t.string :record_type, null: false
  t.json :data, null: false
  t.string :status, default: 'pending', null: false
  t.datetime :sent_at
  t.text :error_message
  t.integer :retry_count, default: 0
  t.timestamps
end

add_index :outgoing_records, :status
add_index :outgoing_records, :record_type
add_index :outgoing_records, :sent_at

create_table :users do |t|
  t.string :name, null: false
  t.string :email, null: false
  t.integer :age
  t.timestamps
end

add_index :users, :email, unique: true

create_table :orders do |t|
  t.references :user, null: false, foreign_key: true
  t.string :product_name, null: false
  t.integer :quantity, default: 1
  t.integer :price_cents, null: false
  t.timestamps
end

add_index :orders, :user_id
```

## DataFlow Configurations

### ServerApp DataFlow

**Name**: "json_rpc_to_database"

**Purpose**: Receive data via JSON-RPC and store in database

**Configuration**:
```ruby
class JsonRpcToDatabaseFlow < ActiveDataFlow::DataFlow
  def initialize
    super(
      name: "json_rpc_to_database",
      source: configure_source,
      sink: configure_sink,
      runtime: configure_runtime
    )
  end

  private

  def configure_source
    ActiveDataFlow::Connector::Source::JsonRpcSource.new(
      host: '0.0.0.0',
      port: 8999
    )
  end

  def configure_sink
    ActiveDataFlow::Connector::Sink::ActiveRecordSink.new(
      model_class: ReceivedRecord,
      batch_size: 10
    )
  end

  def configure_runtime
    ActiveDataFlow::Runtime::Heartbeat.new(interval: 30)
  end

  def transform(record)
    {
      record_type: record['type'] || 'unknown',
      source_id: record['id'],
      data: record,
      received_at: Time.current
    }
  end
end
```

### ClientApp DataFlow

**Name**: "database_to_json_rpc"

**Purpose**: Read data from database and send via JSON-RPC

**Configuration**:
```ruby
class DatabaseToJsonRpcFlow < ActiveDataFlow::DataFlow
  def initialize
    super(
      name: "database_to_json_rpc",
      source: configure_source,
      sink: configure_sink,
      runtime: configure_runtime
    )
  end

  private

  def configure_source
    ActiveDataFlow::Connector::Source::ActiveRecordSource.new(
      scope: OutgoingRecord.pending,
      batch_size: 10
    )
  end

  def configure_sink
    ActiveDataFlow::Connector::Sink::JsonRpcSink.new(
      url: 'http://localhost:8999',
      batch_size: 10
    )
  end

  def configure_runtime
    ActiveDataFlow::Runtime::Heartbeat.new(interval: 30)
  end

  def transform(record)
    # Transform OutgoingRecord to format expected by JSON-RPC
    record.data.merge(
      'id' => record.id,
      'type' => record.record_type,
      'sent_from' => 'client_app'
    )
  end

  def after_write(records)
    # Mark records as sent after successful transmission
    record_ids = records.map { |r| r['id'] }
    OutgoingRecord.where(id: record_ids).update_all(
      status: 'sent',
      sent_at: Time.current
    )
  end
end
```

## Web Interface Design

### ServerApp Web Interface

**Purpose**: Monitor received data and DataFlow status

**Pages**:

1. **Dashboard** (`/`)
   - Recent received records summary
   - DataFlow status and last execution time
   - JSON-RPC server health status
   - Quick statistics (total received, by type, etc.)

2. **Received Records** (`/received_records`)
   - Paginated list of all received records
   - Filter by record type and date range
   - View raw JSON data for each record
   - Search functionality

3. **DataFlows** (`/active_data_flow/data_flows`)
   - ActiveDataFlow engine management interface
   - DataFlow execution history
   - Manual DataFlow triggering
   - Configuration viewing

**Navigation**:
- Header with application name and navigation links
- Breadcrumb navigation for deep pages
- Real-time status indicators

### ClientApp Web Interface

**Purpose**: Create data and monitor sending status

**Pages**:

1. **Dashboard** (`/`)
   - Pending records summary
   - DataFlow status and last execution time
   - JSON-RPC connection health status
   - Quick statistics (total sent, pending, failed)

2. **Create Data** (`/data/new`)
   - Forms for creating Users and Orders
   - Bulk data creation options
   - Preview of data to be sent

3. **Outgoing Records** (`/outgoing_records`)
   - Paginated list of all outgoing records
   - Filter by status, type, and date range
   - Retry failed records
   - View error messages

4. **Users** (`/users`)
   - Manage user records
   - Create new users
   - View user details and associated orders

5. **Orders** (`/orders`)
   - Manage order records
   - Create new orders
   - Associate orders with users

6. **DataFlows** (`/active_data_flow/data_flows`)
   - ActiveDataFlow engine management interface
   - DataFlow execution history
   - Manual DataFlow triggering

## Error Handling

### JSON-RPC Connection Errors

**Scenarios**:
1. ServerApp JSON-RPC server not running
2. Network connectivity issues
3. JSON-RPC protocol errors

**Handling Strategy**:
- ClientApp DataFlow catches connection errors
- Records marked as 'failed' with error message
- Automatic retry mechanism with exponential backoff
- Web interface displays connection status
- Detailed error logging for debugging

### DataFlow Processing Errors

**Scenarios**:
1. Invalid data format in transformation
2. Database constraint violations
3. ActiveDataFlow runtime errors

**Handling Strategy**:
- Try-catch blocks around transformation logic
- Validation before database operations
- Error logging with full context
- Failed records quarantined for manual review
- Web interface shows processing errors

### Data Validation Errors

**Scenarios**:
1. Missing required fields
2. Invalid data types
3. Business rule violations

**Handling Strategy**:
- Model-level validations
- Pre-send validation in ClientApp
- Graceful error display in web interface
- Detailed validation error messages

## Testing Strategy

*A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Unit Tests

**ServerApp Tests**:
- ReceivedRecord model validations and methods
- DataFlow configuration and transformation logic
- JSON-RPC source connector integration
- Controller actions and responses

**ClientApp Tests**:
- OutgoingRecord, User, and Order model validations
- DataFlow configuration and transformation logic
- JSON-RPC sink connector integration
- Controller actions and form handling

### Integration Tests

**JSON-RPC Communication**:
- End-to-end data flow from ClientApp to ServerApp
- Error handling during communication failures
- Batch processing and data integrity
- Heartbeat runtime execution

**Web Interface Tests**:
- Form submissions and data creation
- Dashboard data display and filtering
- DataFlow management interface
- Error message display

### System Tests

**Full Application Tests**:
- Complete user workflows (create data → send → receive → view)
- Multi-record batch processing
- Concurrent DataFlow execution
- Application startup and configuration

## Implementation Notes

### ActiveDataFlow Integration

1. **Engine Mounting**: Both applications mount ActiveDataFlow engine at `/active_data_flow`
2. **Configuration**: Use Rails initializers for ActiveDataFlow and JSON-RPC settings
3. **Database**: Separate SQLite databases for each application
4. **Logging**: Integrate with Rails logger for consistent log formatting

### JSON-RPC Connector Usage

1. **Source Connector**: ServerApp uses JsonRpcSource with embedded Jimson server
2. **Sink Connector**: ClientApp uses JsonRpcSink with Jimson client
3. **Protocol**: Standard JSON-RPC 2.0 with receive_record/receive_records methods
4. **Batching**: Configurable batch sizes for optimal performance

### Rails 8 Conventions

1. **Application Structure**: Standard Rails 8 MVC organization
2. **Database Migrations**: Proper Rails migration files with indexes
3. **Routes**: RESTful routes with ActiveDataFlow engine mounting
4. **Configuration**: Environment-specific settings in config files
5. **Assets**: Rails asset pipeline for CSS/JS management

### Development Setup

1. **Separate Applications**: Two independent Rails applications in subfolders
2. **Port Configuration**: ClientApp on 3001, ServerApp on 3000
3. **Database**: Separate SQLite databases to simulate distributed setup
4. **Startup Scripts**: Convenience scripts to start both applications
5. **Seed Data**: Realistic demo data for immediate testing

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property Reflection

After analyzing all acceptance criteria, I identified several areas where properties could be consolidated:

- **DataFlow Configuration Properties**: Properties 1, 2, 5, and 6 all test DataFlow configuration with different connector types. These can be combined into comprehensive DataFlow configuration properties.
- **Data Processing Properties**: Properties 3, 4, and 7 all test data flow and transformation. These can be combined into end-to-end data processing properties.
- **Error Handling Properties**: Properties 8 and 9 both test error handling scenarios and can be combined.

The following properties represent the unique validation value after removing redundancy:

### Property 1: JSON-RPC Source DataFlow Configuration

*For any* ServerApp DataFlow configuration, the DataFlow should have a JsonRpcSource as its source and an ActiveRecord sink, and should be able to receive and process JSON-RPC data
**Validates: Requirements 1.2, 1.3, 5.1**

### Property 2: JSON-RPC Sink DataFlow Configuration

*For any* ClientApp DataFlow configuration, the DataFlow should have an ActiveRecord source and a JsonRpcSink, and should be able to read and send data via JSON-RPC
**Validates: Requirements 2.2, 2.3, 5.2**

### Property 3: End-to-End Data Flow Processing

*For any* data created in ClientApp, when processed through the complete DataFlow pipeline, the data should appear in ServerApp with proper transformation applied
**Validates: Requirements 1.4, 4.3, 2.4**

### Property 4: JSON-RPC Protocol Compliance

*For any* JSON-RPC communication between ClientApp and ServerApp, the messages should comply with JSON-RPC 2.0 specification format and methods
**Validates: Requirements 3.5**

### Property 5: Batch Processing Consistency

*For any* batch of records processed by JSON-RPC connectors, all records in the batch should be processed together and maintain data integrity
**Validates: Requirements 4.4**

### Property 6: Data Validation and Error Handling

*For any* invalid data or connection failure scenario, the system should handle errors gracefully, log appropriate messages, and implement retry logic where applicable
**Validates: Requirements 4.5, 8.2, 8.4**

### Property 7: Heartbeat Runtime Execution

*For any* configured heartbeat runtime, DataFlow execution should be triggered at the specified intervals and execution status should be properly tracked
**Validates: Requirements 5.3, 5.4**

### Property 8: Data Transformation Consistency

*For any* record processed through DataFlow transformations, the output should maintain data integrity while applying the expected transformations
**Validates: Requirements 4.3**

### Property 9: Execution History Tracking

*For any* DataFlow execution, the system should record execution history, status, and statistics that can be retrieved and displayed
**Validates: Requirements 9.3**

### Property 10: Logging and Monitoring

*For any* DataFlow execution or JSON-RPC communication, appropriate log entries should be created with sufficient detail for debugging and monitoring
**Validates: Requirements 8.1**