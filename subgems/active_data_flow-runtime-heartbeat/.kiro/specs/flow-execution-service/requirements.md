# Flow Execution Service Requirements

## Introduction

The Flow Execution Service provides a service layer that orchestrates the complete lifecycle of DataFlow execution, including status tracking, error handling, and database updates.

## Glossary

- **FlowExecutor**: A service class responsible for executing DataFlows
- **Execution Lifecycle**: The sequence of states a DataFlowRun goes through: pending → in_progress → success/failed
- **Flow Instance**: An instantiated object of a DataFlow subclass that implements the run method
- **Error Capture**: The process of recording error messages and backtraces when execution fails
- **Transaction**: A database operation that ensures all changes succeed or all are rolled back

## Requirements

### Requirement 1: Service Structure

**User Story:** As a developer, I want a service class for flow execution, so that execution logic is separated from controllers and models

#### Acceptance Criteria

1. THE FlowExecutor service SHALL be defined in the ActiveDataFlow::Runtime::Heartbeat module
2. THE FlowExecutor service SHALL accept a DataFlow instance in its initializer
3. THE FlowExecutor service SHALL provide an execute method as the main entry point
4. THE FlowExecutor service SHALL be instantiable with FlowExecutor.new(data_flow)
5. THE FlowExecutor service SHALL be callable with a class method execute(data_flow)

### Requirement 2: DataFlowRun Creation

**User Story:** As a developer, I want execution tracking records created, so that I have a complete history of all execution attempts

#### Acceptance Criteria

1. THE FlowExecutor service SHALL create a DataFlowRun record before execution begins
2. THE DataFlowRun SHALL have status "pending" when created
3. THE DataFlowRun SHALL have started_at set to the current time
4. THE DataFlowRun SHALL be associated with the DataFlow being executed
5. THE FlowExecutor service SHALL persist the DataFlowRun to the database immediately

### Requirement 3: Status Transitions

**User Story:** As a developer, I want status transitions tracked, so that I can monitor execution progress

#### Acceptance Criteria

1. THE FlowExecutor service SHALL update DataFlowRun status to "in_progress" before calling the flow's run method
2. WHEN execution succeeds, THE FlowExecutor service SHALL update status to "success"
3. WHEN execution fails, THE FlowExecutor service SHALL update status to "failed"
4. THE FlowExecutor service SHALL set ended_at timestamp when execution completes
5. THE FlowExecutor service SHALL calculate execution duration from started_at to ended_at

### Requirement 4: Flow Instantiation

**User Story:** As a developer, I want flows instantiated from configuration, so that the correct flow class is executed

#### Acceptance Criteria

1. THE FlowExecutor service SHALL read the flow class name from DataFlow configuration
2. THE FlowExecutor service SHALL constantize the class name to get the flow class
3. THE FlowExecutor service SHALL instantiate the flow class with any required parameters
4. THE FlowExecutor service SHALL pass the DataFlow configuration to the flow instance
5. WHEN the flow class cannot be found, THE FlowExecutor service SHALL raise a descriptive error

### Requirement 5: Flow Execution

**User Story:** As a developer, I want the flow's run method called, so that the actual data processing occurs

#### Acceptance Criteria

1. THE FlowExecutor service SHALL call the run method on the flow instance
2. THE FlowExecutor service SHALL pass any required parameters to the run method
3. THE FlowExecutor service SHALL wait for the run method to complete
4. THE FlowExecutor service SHALL capture the return value of the run method
5. THE FlowExecutor service SHALL allow the run method to raise exceptions

### Requirement 6: Error Handling

**User Story:** As a developer, I want errors captured and logged, so that I can debug failed executions

#### Acceptance Criteria

1. WHEN the flow's run method raises an exception, THE FlowExecutor service SHALL catch it
2. THE FlowExecutor service SHALL store the exception message in error_message
3. THE FlowExecutor service SHALL store the exception backtrace in error_backtrace
4. THE FlowExecutor service SHALL log the error with full details
5. THE FlowExecutor service SHALL not re-raise the exception after capturing it

### Requirement 7: DataFlow Updates

**User Story:** As a developer, I want the DataFlow record updated after execution, so that scheduling logic works correctly

#### Acceptance Criteria

1. THE FlowExecutor service SHALL update DataFlow last_run_at to the current time
2. THE FlowExecutor service SHALL update DataFlow last_run_status to "success" or "failed"
3. THE FlowExecutor service SHALL persist DataFlow changes to the database
4. THE FlowExecutor service SHALL update the DataFlow within the same transaction as the DataFlowRun
5. THE FlowExecutor service SHALL ensure updates occur even if execution fails

### Requirement 8: Transaction Management

**User Story:** As a developer, I want execution wrapped in transactions, so that database state remains consistent

#### Acceptance Criteria

1. THE FlowExecutor service SHALL wrap DataFlowRun creation and updates in a transaction
2. THE FlowExecutor service SHALL commit the transaction when execution succeeds
3. THE FlowExecutor service SHALL commit the transaction when execution fails (to record the failure)
4. THE FlowExecutor service SHALL rollback the transaction only on database errors
5. THE FlowExecutor service SHALL use ActiveRecord transaction blocks

### Requirement 9: Pessimistic Locking

**User Story:** As a developer, I want flows locked during execution, so that concurrent heartbeat requests don't execute the same flow twice

#### Acceptance Criteria

1. THE FlowExecutor service SHALL acquire a pessimistic lock on the DataFlow before execution
2. THE FlowExecutor service SHALL use FOR UPDATE to lock the DataFlow record
3. THE FlowExecutor service SHALL hold the lock for the duration of execution
4. THE FlowExecutor service SHALL release the lock when the transaction completes
5. WHEN a DataFlow is already locked, THE FlowExecutor service SHALL skip it rather than wait

### Requirement 10: Logging

**User Story:** As a developer, I want execution events logged, so that I can monitor and debug flow execution

#### Acceptance Criteria

1. THE FlowExecutor service SHALL log when execution starts with flow name
2. THE FlowExecutor service SHALL log when execution succeeds with duration
3. THE FlowExecutor service SHALL log when execution fails with error message
4. THE FlowExecutor service SHALL use Rails logger with appropriate log levels
5. THE FlowExecutor service SHALL include DataFlow ID and name in all log messages
