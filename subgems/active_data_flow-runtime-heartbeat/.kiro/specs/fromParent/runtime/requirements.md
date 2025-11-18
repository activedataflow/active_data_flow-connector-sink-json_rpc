# Requirements Document

## Introduction

The Data Flow Models feature provides ActiveRecord models for managing data flows and their execution runs, including validations, associations, and business logic for scheduling and tracking flow executions.

## Glossary

- **DataFlow Model**: An ActiveRecord model representing a configured data flow with scheduling and execution settings
- **DataFlowRun Model**: An ActiveRecord model representing a single execution instance of a data flow
- **Run Interval**: The minimum time in seconds that must elapse between executions of a data flow
- **Flow Class**: The Ruby class that implements the actual data flow logic
- **Run Status**: The current state of a flow execution (pending, in_progress, success, failed)

## Requirements

### Requirement 1

**User Story:** As a Rails developer, I want DataFlow records with validations, so that I can ensure data integrity for flow configurations

#### Acceptance Criteria

1. THE DataFlow Model SHALL validate the presence of the `name` attribute
2. THE DataFlow Model SHALL validate the uniqueness of the `name` attribute
3. THE DataFlow Model SHALL validate that `run_interval` is a number greater than 0
4. THE DataFlow Model SHALL validate that `last_run_status` is either "success", "failed", or nil
5. WHEN validation fails, THE DataFlow Model SHALL prevent the record from being saved

### Requirement 2

**User Story:** As a Rails developer, I want DataFlow and DataFlowRun associations, so that I can track all execution runs for each flow

#### Acceptance Criteria

1. THE DataFlow Model SHALL have a `has_many` association to DataFlowRun records
2. THE DataFlowRun Model SHALL have a `belongs_to` association to a DataFlow record
3. WHEN a DataFlow is destroyed, THE DataFlow Model SHALL destroy all associated DataFlowRun records
4. THE DataFlow Model SHALL use the foreign key `data_flow_id` for the association
5. THE DataFlowRun Model SHALL validate the presence of the associated DataFlow

### Requirement 3

**User Story:** As a system scheduler, I want to identify flows due to run, so that I can execute them at the appropriate intervals

#### Acceptance Criteria

1. THE DataFlow Model SHALL provide a `due_to_run` class method that returns flows needing execution
2. WHEN a flow has never run, THE DataFlow Model SHALL include it in the `due_to_run` results
3. WHEN the time since `last_run_at` exceeds `run_interval`, THE DataFlow Model SHALL include the flow in `due_to_run` results
4. WHEN a flow is disabled, THE DataFlow Model SHALL exclude it from `due_to_run` results
5. THE DataFlow Model SHALL calculate time differences using the current time

### Requirement 4

**User Story:** As a Rails developer, I want to trigger flow execution, so that I can manually run flows on demand

#### Acceptance Criteria

1. THE DataFlow Model SHALL provide a `trigger_run!` instance method
2. WHEN `trigger_run!` is called, THE DataFlow Model SHALL delegate execution to the FlowExecutor service
3. THE DataFlow Model SHALL pass itself as an argument to the FlowExecutor
4. THE DataFlow Model SHALL provide a `flow_class` method that returns the Ruby class for the flow

### Requirement 5

**User Story:** As a Rails developer, I want DataFlowRun records with status tracking, so that I can monitor execution history and outcomes

#### Acceptance Criteria

1. THE DataFlowRun Model SHALL validate that `status` is one of: "pending", "in_progress", "success", or "failed"
2. THE DataFlowRun Model SHALL validate the presence of `started_at`
3. THE DataFlowRun Model SHALL provide a `duration` method that calculates execution time
4. WHEN `ended_at` is nil, THE DataFlowRun Model SHALL return nil for duration
5. WHEN `ended_at` is present, THE DataFlowRun Model SHALL return the difference between `ended_at` and `started_at`

### Requirement 6

**User Story:** As a Rails developer, I want convenience methods for run status, so that I can easily check execution outcomes

#### Acceptance Criteria

1. THE DataFlowRun Model SHALL provide a `success?` method that returns true when status is "success"
2. THE DataFlowRun Model SHALL provide a `failed?` method that returns true when status is "failed"
3. WHEN status is not "success", THE DataFlowRun Model SHALL return false for `success?`
4. WHEN status is not "failed", THE DataFlowRun Model SHALL return false for `failed?`

### Requirement 7

**User Story:** As a Rails developer, I want configuration serialization, so that I can store complex flow settings as JSON

#### Acceptance Criteria

1. THE DataFlow Model SHALL serialize the `configuration` attribute as JSON
2. THE DataFlow Model SHALL allow storing hash data in the configuration attribute
3. THE DataFlow Model SHALL retrieve configuration data as a hash
4. THE DataFlow Model SHALL extract the flow class name from the configuration hash
