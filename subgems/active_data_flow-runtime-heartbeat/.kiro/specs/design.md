# Heartbeat Runtime Design Document

## Overview

The Heartbeat Runtime provides a Ruby module for executing DataFlows via periodic HTTP endpoint triggers. This subgem implements the `ActiveDataflow::Runtime::Heartbeat` runtime and integrates with Rails applications.

See: `../../../../../.kiro/specs/requirements.md` - Requirement 5 (Heartbeat Runtime)
See: `../../../../../.kiro/specs/design.md` - Section 4 (Runtime Abstractions)

## Architecture

### Components

1. **Module Structure** (`ActiveDataFlow::Runtime::Heartbeat`)
   - Namespaced module
   - Provides models, controllers, and services
   - Integrates with Rails applications

2. **Models**
   - `DataFlow` - Stores flow configurations
   - `DataFlowRun` - Tracks execution history

3. **Controllers**
   - `DataFlowsController` - Heartbeat endpoint with security

4. **Services**
   - `FlowExecutor` - Orchestrates flow execution lifecycle

5. **Configuration**
   - Authentication token support
   - IP whitelisting
   - Configurable execution intervals

## Database Schema

### data_flows Table

```ruby
create_table :data_flows do |t|
  t.string :name, null: false, index: { unique: true }
  t.boolean :enabled, default: true
  t.integer :run_interval, null: false  # seconds
  t.datetime :last_run_at
  t.string :last_run_status  # 'success' or 'failed'
  t.text :configuration  # JSON serialized
  t.timestamps
end
```

### data_flow_runs Table

```ruby
create_table :data_flow_runs do |t|
  t.references :data_flow, null: false, foreign_key: true
  t.string :status, null: false  # 'pending', 'in_progress', 'success', 'failed'
  t.datetime :started_at, null: false
  t.datetime :ended_at
  t.text :error_message
  t.text :error_backtrace
  t.timestamps
end
```

## API Endpoints

### POST /active_data_flow/data_flows/heartbeat

Triggers execution of all DataFlows that are due to run.

**Security:**
- Requires `X-Heartbeat-Token` header (if authentication enabled)
- IP whitelisting support (if enabled)

**Response:**
```json
{
  "flows_due": 3,
  "flows_triggered": 3,
  "timestamp": "2025-11-17T10:30:00Z"
}
```

## Execution Flow

1. Heartbeat endpoint receives POST request
2. Authenticate request (token + IP)
3. Query `DataFlow.due_to_run` (enabled flows past their interval)
4. Lock flows with `FOR UPDATE SKIP LOCKED` to prevent concurrent execution
5. For each flow:
   - Create `DataFlowRun` record (status: pending → in_progress)
   - Instantiate flow class from configuration
   - Execute flow's `run` method
   - Update status (success/failed) with timestamps
6. Return summary response

## Error Handling

- **Authentication Failure**: 401 Unauthorized
- **IP Whitelist Rejection**: 403 Forbidden
- **Flow Execution Error**: Log error, mark run as failed, continue with next flow
- **Database Lock Timeout**: Skip locked flows, they're being processed elsewhere

## Configuration

```ruby
# config/initializers/active_data_flow.rb
ActiveDataFlow::Runtime::Heartbeat.configure do |config|
  config.authentication_enabled = true
  config.authentication_token = ENV['HEARTBEAT_TOKEN']
  config.ip_whitelisting_enabled = true
  config.whitelisted_ips = ['10.0.0.0/8', '172.16.0.0/12']
end
```

## Testing Strategy

See: `../../../../../.kiro/steering/test_driven_design.md`

- **Unit Tests**: Models, services
- **Controller Tests**: Heartbeat endpoint, authentication, IP whitelisting
- **Integration Tests**: End-to-end flow execution
- **Dummy App**: Rails dummy app for testing engine integration

## Dependencies

- `active_data_flow` (core gem)
- `rails` (>= 6.0)
- `activerecord`

## File Structure

```
subgems/runtime/heartbeat/
├── app/
│   ├── controllers/active_data_flow/runtime/heartbeat/
│   ├── models/active_data_flow/runtime/heartbeat/
│   └── services/active_data_flow/runtime/heartbeat/
├── config/
│   └── routes.rb
├── db/
│   └── migrate/
├── lib/
│   └── active_data_flow/
│       └── runtime/
│           └── heartbeat/
│               ├── version.rb
│               └── configuration.rb
└── spec/
    ├── controllers/
    ├── models/
    ├── services/
    └── integration/
```

## Implementation Notes

- Module uses namespacing to avoid conflicts
- Database locking prevents duplicate execution in multi-process environments
- Errors in one flow don't prevent others from running
- Comprehensive logging for observability
- Configuration stored as JSON for flexibility

See: `requirements.md` for detailed requirements
See: `../../../../../.kiro/specs/tasks.md` - Tasks 8.1, 8.2, 8.3 for implementation tasks
