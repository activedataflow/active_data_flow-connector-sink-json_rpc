# Rails Engine Structure

## Overview

ActiveDataFlow includes a Rails engine (`ActiveDataFlow::RailsHeartbeatApp::Engine`) that provides a turnkey solution for managing DataFlows within Rails applications. The engine is isolated and follows Rails conventions.

## App Directory Structure

```
app/
├── controllers/
│   └── active_data_flow/
│       └── rails_heartbeat_app/
│           └── data_flows_controller.rb
├── models/
│   └── active_data_flow/
│       └── rails_heartbeat_app/
│           ├── data_flow.rb
│           └── data_flow_run.rb
└── services/
    └── active_data_flow/
        └── rails_heartbeat_app/
            └── flow_executor.rb
```

## Components

### Models

**DataFlow** (`app/models/active_data_flow/rails_heartbeat_app/data_flow.rb`)
- Represents a configured DataFlow pipeline
- Attributes: name, enabled, run_interval, last_run_at, last_run_status, configuration
- Associations: has_many :data_flow_runs
- Key methods:
  - `self.due_to_run` - Returns flows ready for execution
  - `trigger_run!` - Manually triggers flow execution
  - `flow_class` - Resolves the DataFlow class from configuration

**DataFlowRun** (`app/models/active_data_flow/rails_heartbeat_app/data_flow_run.rb`)
- Tracks individual execution runs of a DataFlow
- Attributes: status, started_at, ended_at, error_message, error_backtrace
- Associations: belongs_to :data_flow
- Status values: pending, in_progress, success, failed
- Key methods:
  - `duration` - Calculates run duration
  - `success?` / `failed?` - Status checks

### Controllers

**DataFlowsController** (`app/controllers/active_data_flow/rails_heartbeat_app/data_flows_controller.rb`)
- Handles heartbeat endpoint for triggering DataFlow execution
- Security features:
  - Token-based authentication via X-Heartbeat-Token header
  - IP whitelisting support
  - CSRF protection disabled for API endpoint
- Key actions:
  - `heartbeat` - POST endpoint that executes due DataFlows

### Services

**FlowExecutor** (`app/services/active_data_flow/rails_heartbeat_app/flow_executor.rb`)
- Orchestrates DataFlow execution lifecycle
- Responsibilities:
  - Creates DataFlowRun records
  - Instantiates and executes flow classes
  - Updates status and timestamps
  - Captures errors and backtraces
- Key methods:
  - `self.execute(data_flow)` - Class method entry point
  - `execute` - Instance method that runs the flow

## Engine Configuration

The engine is defined in `hide/subgems/runtime/heartbeat/lib/active_data_flow/rails_heartbeat_app/engine.rb`:
- Isolated namespace: `ActiveDataFlow::RailsHeartbeatApp`
- Test framework: RSpec
- Eager loads: models, controllers, services

## Routes

Defined in `hide/subgems/runtime/heartbeat/config/routes.rb`:
```ruby
post "/data_flows/heartbeat", to: "data_flows#heartbeat", as: :heartbeat
```

Mounted in host application as:
```ruby
mount ActiveDataFlow::RailsHeartbeatApp::Engine => "/active_data_flow"
```

Full path: `POST /active_data_flow/data_flows/heartbeat`

## Database Schema

The engine expects these tables:
- `data_flows` - Stores DataFlow configurations
- `data_flow_runs` - Tracks execution history

See subgem migrations for detailed schema definitions.

## Security Configuration

The engine supports configurable security:
- `authentication_enabled` - Enable/disable token authentication
- `authentication_token` - Secret token for heartbeat endpoint
- `ip_whitelisting_enabled` - Enable/disable IP restrictions
- `whitelisted_ips` - Array of allowed IP addresses

## Usage Pattern

1. Define a DataFlow class that inherits from base DataFlow
2. Create a DataFlow record with configuration pointing to the class
3. Enable the DataFlow and set run_interval
4. Heartbeat endpoint triggers execution of due flows
5. FlowExecutor manages lifecycle and error handling
6. DataFlowRun records track execution history

## Design Principles

- **Isolation**: Engine uses isolated namespace to avoid conflicts
- **Security**: Multiple layers (authentication, IP whitelisting)
- **Observability**: Comprehensive logging and run tracking
- **Resilience**: Errors in one flow don't prevent others from running
- **Concurrency**: Uses database locking (FOR UPDATE SKIP LOCKED) to prevent duplicate execution

See: `.kiro/specs/requirements.md` - Requirement 6 (Rails Engine Integration)
See: `.kiro/specs/design.md` - Section 6 (Rails Engine Integration)
