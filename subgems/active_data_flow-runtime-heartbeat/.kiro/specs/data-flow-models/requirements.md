# Data Flow Models Requirements

## Introduction

The Data Flow Models feature provides ActiveRecord models for managing DataFlows and tracking their execution history through DataFlowRun records.

## Glossary

- **DataFlow**: An ActiveRecord model representing a configured data flow with scheduling parameters
- **DataFlowRun**: An ActiveRecord model tracking individual execution attempts of a DataFlow
- **Run Interval**: The minimum time in seconds between executions of a DataFlow
- **Pessimistic Locking**: A database locking strategy using FOR UPDATE to prevent concurrent execution
- **Scope**: An ActiveRecord query method that returns a filtered collection

## Requirements

### Requirement 1: DataFlow Model Structure

**User Story:** As a developer, I want a DataFlow model to store flow configurations, so that I can manage multiple flows with different schedules

#### Acceptance Criteria

1. THE DataFlow model SHALL inherit from ApplicationRecord
2. THE DataFlow model SHALL have a name string column that is required
3. THE DataFlow model SHALL have an enabled boolean column with default true
4. THE DataFlow model SHALL have a run_interval integer column that is required
5. THE DataFlow model SHALL have a last_run_at datetime column
6. THE DataFlow model SHALL have a last_run_status string column
7. THE DataFlow model SHALL have a configuration text column
8. THE DataFlow model SHALL have timestamps for created_at and updated_at

### Requirement 2: DataFlow Validations

**User Story:** As a developer, I want DataFlow validations, so that invalid flow configurations are rejected

#### Acceptance Criteria

1. THE DataFlow model SHALL validate presence of name
2. THE DataFlow model SHALL validate uniqueness of name
3. THE DataFlow model SHALL validate presence of run_interval
4. THE DataFlow model SHALL validate that run_interval is greater than zero
5. THE DataFlow model SHALL validate that last_run_status is either "success" or "failed" when present

### Requirement 3: DataFlow Associations

**User Story:** As a developer, I want DataFlow associations, so that I can access execution history

#### Acceptance Criteria

1. THE DataFlow model SHALL have a has_many association to data_flow_runs
2. THE has_many association SHALL be ordered by created_at descending
3. THE has_many association SHALL use dependent destroy to clean up runs when a flow is deleted
4. THE DataFlow model SHALL provide access to the most recent run via a last_run method
5. THE DataFlow model SHALL provide access to successful runs via a successful_runs association

### Requirement 4: DataFlow Scheduling Logic

**User Story:** As a developer, I want to query flows due to run, so that the heartbeat endpoint can execute them

#### Acceptance Criteria

1. THE DataFlow model SHALL provide a due_to_run scope
2. THE due_to_run scope SHALL return only enabled flows
3. THE due_to_run scope SHALL return flows where last_run_at is nil
4. THE due_to_run scope SHALL return flows where last_run_at plus run_interval is before the current time
5. THE due_to_run scope SHALL order results by last_run_at ascending with nulls first

### Requirement 5: DataFlow Locking

**User Story:** As a developer, I want pessimistic locking on DataFlows, so that concurrent heartbeat requests don't execute the same flow twice

#### Acceptance Criteria

1. THE DataFlow model SHALL support pessimistic locking with lock! method
2. THE due_to_run scope SHALL support FOR UPDATE SKIP LOCKED when chained with lock
3. WHEN a DataFlow is locked, THE DataFlow model SHALL prevent other processes from locking the same record
4. WHEN a DataFlow is locked and unavailable, THE DataFlow model SHALL skip it rather than wait
5. THE DataFlow model SHALL release locks when the transaction completes

### Requirement 6: DataFlowRun Model Structure

**User Story:** As a developer, I want a DataFlowRun model to track execution history, so that I can monitor performance and debug failures

#### Acceptance Criteria

1. THE DataFlowRun model SHALL inherit from ApplicationRecord
2. THE DataFlowRun model SHALL have a data_flow_id integer column that is required
3. THE DataFlowRun model SHALL have a status string column that is required
4. THE DataFlowRun model SHALL have a started_at datetime column that is required
5. THE DataFlowRun model SHALL have an ended_at datetime column
6. THE DataFlowRun model SHALL have an error_message text column
7. THE DataFlowRun model SHALL have an error_backtrace text column
8. THE DataFlowRun model SHALL have timestamps for created_at and updated_at

### Requirement 7: DataFlowRun Validations

**User Story:** As a developer, I want DataFlowRun validations, so that execution records are consistent

#### Acceptance Criteria

1. THE DataFlowRun model SHALL validate presence of data_flow_id
2. THE DataFlowRun model SHALL validate presence of status
3. THE DataFlowRun model SHALL validate presence of started_at
4. THE DataFlowRun model SHALL validate that status is one of: "pending", "in_progress", "success", "failed"
5. THE DataFlowRun model SHALL validate that ended_at is after started_at when both are present

### Requirement 8: DataFlowRun Associations

**User Story:** As a developer, I want DataFlowRun associations, so that I can access the parent DataFlow

#### Acceptance Criteria

1. THE DataFlowRun model SHALL have a belongs_to association to data_flow
2. THE belongs_to association SHALL be required
3. THE DataFlowRun model SHALL provide access to the parent flow's name via delegation
4. THE DataFlowRun model SHALL provide access to the parent flow's configuration via delegation
5. THE DataFlowRun model SHALL cascade delete when the parent DataFlow is destroyed

### Requirement 9: DataFlowRun Status Management

**User Story:** As a developer, I want status transition methods, so that I can update run status safely

#### Acceptance Criteria

1. THE DataFlowRun model SHALL provide a start! method that sets status to "in_progress"
2. THE DataFlowRun model SHALL provide a succeed! method that sets status to "success" and ended_at
3. THE DataFlowRun model SHALL provide a fail! method that sets status to "failed", ended_at, and error details
4. THE start! method SHALL set started_at to the current time
5. THE succeed! and fail! methods SHALL calculate and store execution duration

### Requirement 10: DataFlowRun Query Scopes

**User Story:** As a developer, I want query scopes for DataFlowRuns, so that I can filter by status and time

#### Acceptance Criteria

1. THE DataFlowRun model SHALL provide a pending scope for runs with status "pending"
2. THE DataFlowRun model SHALL provide an in_progress scope for runs with status "in_progress"
3. THE DataFlowRun model SHALL provide a completed scope for runs with status "success" or "failed"
4. THE DataFlowRun model SHALL provide a failed scope for runs with status "failed"
5. THE DataFlowRun model SHALL provide a recent scope that returns runs from the last 24 hours
