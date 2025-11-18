# Heartbeat Runtime Requirements Document

## Introduction

The Heartbeat Runtime is a Ruby gem that provides scheduled data flow execution capabilities through an HTTP heartbeat endpoint. It allows external schedulers to trigger execution of configured data flows at specified intervals, with built-in security features including token authentication and IP whitelisting.

## Glossary

- **DataFlow**: An ActiveRecord model representing a configured data flow with scheduling parameters
- **DataFlowRun**: An ActiveRecord model tracking individual execution attempts of a DataFlow
- **Heartbeat Endpoint**: An HTTP POST endpoint that triggers execution of due DataFlows
- **Authentication Token**: A secret string used to authenticate heartbeat requests
- **IP Whitelisting**: A security mechanism that restricts access based on source IP address
- **Pessimistic Locking**: A database locking strategy using FOR UPDATE to prevent concurrent execution
- **Flow Executor**: A service class responsible for orchestrating DataFlow execution lifecycle

## Requirements

### Requirement 1: Module Structure

**User Story:** As a Rails developer, I want the gem to integrate with my Rails application, so that I can use it seamlessly

#### Acceptance Criteria

1. THE Heartbeat Runtime SHALL be defined in the ActiveDataFlow::Runtime::Heartbeat module
2. THE Heartbeat Runtime SHALL provide models in the ActiveDataFlow::Runtime::Heartbeat namespace
3. THE Heartbeat Runtime SHALL provide controllers in the ActiveDataFlow::Runtime::Heartbeat namespace
4. THE Heartbeat Runtime SHALL provide services in the ActiveDataFlow::Runtime::Heartbeat namespace
5. THE Heartbeat Runtime SHALL be loadable via require statements

### Requirement 2: DataFlow Model

**User Story:** As a developer, I want to store DataFlow configurations in the database, so that I can manage multiple flows with different schedules

#### Acceptance Criteria

1. THE DataFlow model SHALL have a name field that is required and unique
2. THE DataFlow model SHALL have an enabled boolean field with a default value of true
3. THE DataFlow model SHALL have a run_interval integer field that is required and stores seconds
4. THE DataFlow model SHALL have a last_run_at datetime field that stores the timestamp of the last execution
5. THE DataFlow model SHALL have a last_run_status string field that stores either "success" or "failed"
6. THE DataFlow model SHALL have a configuration text field that stores JSON serialized data
7. THE DataFlow model SHALL have a has_many association to DataFlowRun records
8. WHEN querying for flows due to run, THE DataFlow model SHALL return enabled flows where last_run_at plus run_interval is before the current time

### Requirement 3: DataFlowRun Model

**User Story:** As a developer, I want to track execution history for each DataFlow, so that I can monitor performance and debug failures

#### Acceptance Criteria

1. THE DataFlowRun model SHALL have a data_flow_id foreign key that is required
2. THE DataFlowRun model SHALL have a status string field that is required
3. THE DataFlowRun model SHALL have a started_at datetime field that is required
4. THE DataFlowRun model SHALL have an ended_at datetime field that stores completion timestamp
5. THE DataFlowRun model SHALL have an error_message text field that stores failure messages
6. THE DataFlowRun model SHALL have an error_backtrace text field that stores stack traces
7. THE DataFlowRun model SHALL have a belongs_to association to DataFlow
8. THE DataFlowRun model SHALL support status values: "pending", "in_progress", "success", "failed"

### Requirement 4: Configuration Management

**User Story:** As a developer, I want to configure authentication and IP whitelisting, so that I can secure the heartbeat endpoint

#### Acceptance Criteria

1. THE Configuration class SHALL provide an authentication_enabled boolean setting
2. THE Configuration class SHALL provide an authentication_token string setting
3. THE Configuration class SHALL provide an ip_whitelisting_enabled boolean setting
4. THE Configuration class SHALL provide a whitelisted_ips array setting
5. THE Configuration class SHALL be accessible via ActiveDataFlow::Runtime::Heartbeat.configuration
6. THE Configuration class SHALL support a configure block for setting values

### Requirement 5: Heartbeat Endpoint

**User Story:** As an external scheduler, I want to trigger DataFlow execution via HTTP POST, so that I can control when flows run

#### Acceptance Criteria

1. THE DataFlowsController SHALL provide a POST endpoint at /active_data_flow/data_flows/heartbeat
2. WHEN authentication is enabled, THE DataFlowsController SHALL require an X-Heartbeat-Token header
3. WHEN the authentication token is invalid, THE DataFlowsController SHALL return HTTP 401 Unauthorized
4. WHEN IP whitelisting is enabled, THE DataFlowsController SHALL verify the request IP is in the whitelist
5. WHEN the request IP is not whitelisted, THE DataFlowsController SHALL return HTTP 403 Forbidden
6. WHEN authentication succeeds, THE DataFlowsController SHALL query for DataFlows due to run
7. WHEN DataFlows are due, THE DataFlowsController SHALL trigger execution for each flow
8. THE DataFlowsController SHALL return a JSON response with flows_due, flows_triggered, and timestamp
9. THE DataFlowsController SHALL skip CSRF token verification for the heartbeat endpoint

### Requirement 6: Flow Execution Service

**User Story:** As a developer, I want flows executed reliably with error handling, so that failures don't prevent other flows from running

#### Acceptance Criteria

1. THE FlowExecutor service SHALL accept a DataFlow instance for execution
2. THE FlowExecutor service SHALL create a DataFlowRun record with status "pending"
3. THE FlowExecutor service SHALL update the DataFlowRun status to "in_progress" before execution
4. THE FlowExecutor service SHALL set the started_at timestamp when execution begins
5. THE FlowExecutor service SHALL instantiate the flow class from the DataFlow configuration
6. THE FlowExecutor service SHALL call the run method on the instantiated flow
7. WHEN execution succeeds, THE FlowExecutor service SHALL update status to "success" and set ended_at
8. WHEN execution fails, THE FlowExecutor service SHALL update status to "failed" and capture error_message and error_backtrace
9. THE FlowExecutor service SHALL update the DataFlow last_run_at and last_run_status fields
10. THE FlowExecutor service SHALL use pessimistic locking with FOR UPDATE SKIP LOCKED to prevent concurrent execution

### Requirement 7: Install Generator

**User Story:** As a Rails developer, I want a generator to install the gem, so that I can set up the database and configuration quickly

#### Acceptance Criteria

1. THE install generator SHALL be invoked with rails generate active_data_flow:runtime:heartbeat:install
2. THE install generator SHALL copy database migrations to the host application
3. THE install generator SHALL create an initializer file at config/initializers/active_data_flow.rb
4. THE install generator SHALL include configuration examples in the initializer
5. THE install generator SHALL output instructions for running migrations

### Requirement 8: Flow Generator

**User Story:** As a developer, I want a generator to create DataFlow subclasses, so that I can quickly scaffold new flows

#### Acceptance Criteria

1. THE flow generator SHALL be invoked with rails generate active_data_flow:runtime:heartbeat:flow NAME
2. THE flow generator SHALL create a DataFlow subclass file
3. THE flow generator SHALL include a run method stub in the generated class
4. THE flow generator SHALL namespace the generated class appropriately
5. THE flow generator SHALL output instructions for registering the flow
