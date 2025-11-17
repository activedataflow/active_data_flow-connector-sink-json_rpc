# Requirements Document

## Introduction

The Flow Execution Service feature provides a service class that orchestrates the execution of data flows, including run record creation, flow instantiation, status tracking, and error handling.

## Glossary

- **FlowExecutor Service**: A service class responsible for executing data flows and managing their lifecycle
- **Run Record**: A DataFlowRun instance that tracks a single execution of a data flow
- **Flow Instance**: An instantiated object of the flow class that performs the actual data processing
- **Flow Configuration**: A hash containing settings and parameters for flow execution
- **Execution Lifecycle**: The sequence of states a flow goes through: pending → in_progress → success/failed

## Requirements

### Requirement 1

**User Story:** As a system component, I want to execute a data flow, so that the configured data processing logic runs

#### Acceptance Criteria

1. THE FlowExecutor Service SHALL provide a class method `execute` that accepts a DataFlow
2. WHEN `execute` is called, THE FlowExecutor Service SHALL create a new instance with the DataFlow
3. THE FlowExecutor Service SHALL call the instance `execute` method to perform the execution
4. THE FlowExecutor Service SHALL return the result of the execution
5. THE FlowExecutor Service SHALL complete all execution steps in sequence

### Requirement 2

**User Story:** As a system administrator, I want run records created for each execution, so that I can track execution history

#### Acceptance Criteria

1. WHEN execution begins, THE FlowExecutor Service SHALL create a DataFlowRun record with status "pending"
2. THE FlowExecutor Service SHALL set the `started_at` timestamp to the current time
3. THE FlowExecutor Service SHALL update the run status to "in_progress" before executing the flow
4. THE FlowExecutor Service SHALL associate the run record with the DataFlow
5. THE FlowExecutor Service SHALL store the run record for later status updates

### Requirement 3

**User Story:** As a system component, I want flow instantiation and execution, so that the configured flow logic runs with the correct configuration

#### Acceptance Criteria

1. THE FlowExecutor Service SHALL retrieve the flow class from the DataFlow configuration
2. THE FlowExecutor Service SHALL instantiate the flow class with the DataFlow configuration
3. THE FlowExecutor Service SHALL call the `run` method on the flow instance
4. THE FlowExecutor Service SHALL use the DataFlow's `flow_class` method to get the class
5. THE FlowExecutor Service SHALL pass the complete configuration to the flow constructor

### Requirement 4

**User Story:** As a system administrator, I want successful execution tracking, so that I can monitor when flows complete successfully

#### Acceptance Criteria

1. WHEN flow execution completes without errors, THE FlowExecutor Service SHALL update the DataFlow's `last_run_at` to the current time
2. THE FlowExecutor Service SHALL update the DataFlow's `last_run_status` to "success"
3. THE FlowExecutor Service SHALL update the run record status to "success"
4. THE FlowExecutor Service SHALL set the run record's `ended_at` to the current time
5. THE FlowExecutor Service SHALL persist all status updates to the database

### Requirement 5

**User Story:** As a system administrator, I want failure tracking with error details, so that I can diagnose and fix issues

#### Acceptance Criteria

1. WHEN an exception occurs during execution, THE FlowExecutor Service SHALL update the DataFlow's `last_run_status` to "failed"
2. THE FlowExecutor Service SHALL update the DataFlow's `last_run_at` to the current time
3. THE FlowExecutor Service SHALL update the run record status to "failed"
4. THE FlowExecutor Service SHALL store the exception message in the run record's `error_message` field
5. THE FlowExecutor Service SHALL store the exception backtrace in the run record's `error_backtrace` field
6. THE FlowExecutor Service SHALL set the run record's `ended_at` to the current time
7. WHEN an exception occurs, THE FlowExecutor Service SHALL re-raise the exception after recording the failure

### Requirement 6

**User Story:** As a Rails developer, I want a simple service interface, so that I can easily execute flows from different parts of the application

#### Acceptance Criteria

1. THE FlowExecutor Service SHALL provide a class-level `execute` method as the primary interface
2. THE FlowExecutor Service SHALL encapsulate all execution logic in private methods
3. THE FlowExecutor Service SHALL not expose internal implementation details
4. THE FlowExecutor Service SHALL handle all database updates internally
5. THE FlowExecutor Service SHALL manage the complete execution lifecycle from a single entry point
