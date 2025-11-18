# Requirements Document

## Introduction

The Heartbeat Endpoint feature provides an HTTP endpoint that external schedulers can call to trigger execution of data flows that are due to run, with built-in authentication and IP whitelisting security measures.

## Glossary

- **Heartbeat Endpoint**: An HTTP endpoint that triggers execution of due data flows
- **Authentication Token**: A secret string passed in the X-Heartbeat-Token header for request verification
- **IP Whitelist**: A list of allowed source IP addresses that can access the endpoint
- **Pessimistic Locking**: A database locking mechanism using "FOR UPDATE SKIP LOCKED" to prevent concurrent execution
- **DataFlowsController**: The Rails controller that handles heartbeat HTTP requests

## Requirements

### Requirement 1

**User Story:** As an external scheduler, I want to call a heartbeat endpoint, so that I can trigger execution of flows that are due to run

#### Acceptance Criteria

1. THE DataFlowsController SHALL provide a `heartbeat` action accessible via HTTP
2. WHEN the heartbeat action is called, THE DataFlowsController SHALL query for flows due to run
3. THE DataFlowsController SHALL execute each flow that is due to run
4. THE DataFlowsController SHALL return a JSON response with flows_due count, flows_triggered count, and timestamp
5. THE DataFlowsController SHALL use pessimistic locking with "FOR UPDATE SKIP LOCKED" to prevent concurrent execution

### Requirement 2

**User Story:** As a system administrator, I want token-based authentication, so that only authorized schedulers can trigger the heartbeat

#### Acceptance Criteria

1. WHEN authentication is enabled, THE DataFlowsController SHALL require an X-Heartbeat-Token header
2. THE DataFlowsController SHALL compare the provided token with the configured authentication token using secure comparison
3. WHEN tokens do not match, THE DataFlowsController SHALL return a 401 Unauthorized response with error message
4. WHEN authentication is disabled, THE DataFlowsController SHALL skip token verification
5. WHEN authentication fails, THE DataFlowsController SHALL log a warning with the source IP and timestamp

### Requirement 3

**User Story:** As a system administrator, I want IP whitelisting, so that only requests from approved IP addresses can access the heartbeat endpoint

#### Acceptance Criteria

1. WHEN IP whitelisting is enabled, THE DataFlowsController SHALL check the request source IP against the whitelist
2. WHEN the source IP is not in the whitelist, THE DataFlowsController SHALL return a 403 Forbidden response with error message
3. WHEN IP whitelisting is disabled, THE DataFlowsController SHALL skip IP verification
4. THE DataFlowsController SHALL extract the source IP using `request.remote_ip`
5. WHEN IP check fails, THE DataFlowsController SHALL log a warning with the rejected IP and timestamp

### Requirement 4

**User Story:** As an external scheduler, I want error handling, so that I receive appropriate responses when issues occur

#### Acceptance Criteria

1. WHEN an exception occurs during heartbeat processing, THE DataFlowsController SHALL return a 500 Internal Server Error response
2. THE DataFlowsController SHALL include the error message in the JSON response
3. WHEN a flow execution fails, THE DataFlowsController SHALL log the error and continue with remaining flows
4. THE DataFlowsController SHALL not halt processing of subsequent flows when one flow fails
5. THE DataFlowsController SHALL track the count of successfully triggered flows separately from flows due

### Requirement 5

**User Story:** As a Rails developer, I want CSRF protection disabled for the heartbeat endpoint, so that external schedulers can call it without Rails tokens

#### Acceptance Criteria

1. THE DataFlowsController SHALL skip CSRF token verification for all actions
2. THE DataFlowsController SHALL use `skip_before_action :verify_authenticity_token`
3. THE DataFlowsController SHALL allow POST requests without authenticity tokens
4. THE DataFlowsController SHALL maintain other security measures (authentication, IP whitelisting)
