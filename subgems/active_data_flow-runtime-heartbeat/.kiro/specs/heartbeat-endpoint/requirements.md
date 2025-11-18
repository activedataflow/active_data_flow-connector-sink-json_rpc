# Heartbeat Endpoint Requirements

## Introduction

The Heartbeat Endpoint feature provides an HTTP POST endpoint that external schedulers can call to trigger execution of DataFlows that are due to run.

## Glossary

- **Heartbeat Endpoint**: An HTTP POST endpoint at /active_data_flow/data_flows/heartbeat
- **DataFlowsController**: The Rails controller that handles heartbeat requests
- **Authentication Token**: A secret string passed in the X-Heartbeat-Token header
- **IP Whitelisting**: A security mechanism that restricts access based on source IP address
- **CSRF Protection**: Rails security feature that validates request authenticity tokens

## Requirements

### Requirement 1: Controller Structure

**User Story:** As a developer, I want a controller for the heartbeat endpoint, so that external schedulers can trigger flow execution

#### Acceptance Criteria

1. THE DataFlowsController SHALL inherit from ApplicationController
2. THE DataFlowsController SHALL be namespaced under ActiveDataFlow::Runtime::Heartbeat
3. THE DataFlowsController SHALL define a heartbeat action
4. THE DataFlowsController SHALL skip CSRF token verification for the heartbeat action
5. THE DataFlowsController SHALL respond only to POST requests

### Requirement 2: Authentication

**User Story:** As a developer, I want token-based authentication, so that only authorized schedulers can trigger flows

#### Acceptance Criteria

1. WHEN authentication is enabled, THE DataFlowsController SHALL require an X-Heartbeat-Token header
2. THE DataFlowsController SHALL compare the provided token with the configured authentication_token
3. THE DataFlowsController SHALL use secure comparison to prevent timing attacks
4. WHEN the token is missing, THE DataFlowsController SHALL return HTTP 401 Unauthorized
5. WHEN the token is invalid, THE DataFlowsController SHALL return HTTP 401 Unauthorized
6. WHEN authentication is disabled, THE DataFlowsController SHALL skip token validation

### Requirement 3: IP Whitelisting

**User Story:** As a developer, I want IP whitelisting, so that only requests from trusted sources are processed

#### Acceptance Criteria

1. WHEN IP whitelisting is enabled, THE DataFlowsController SHALL extract the request IP address
2. THE DataFlowsController SHALL check if the request IP matches any whitelisted IP or CIDR range
3. THE DataFlowsController SHALL support both individual IP addresses and CIDR notation
4. WHEN the IP is not whitelisted, THE DataFlowsController SHALL return HTTP 403 Forbidden
5. WHEN IP whitelisting is disabled, THE DataFlowsController SHALL skip IP validation

### Requirement 4: Flow Execution Triggering

**User Story:** As an external scheduler, I want the endpoint to execute due flows, so that I can control when flows run

#### Acceptance Criteria

1. THE DataFlowsController SHALL query for DataFlows due to run using the due_to_run scope
2. THE DataFlowsController SHALL use pessimistic locking with SKIP LOCKED to prevent concurrent execution
3. THE DataFlowsController SHALL iterate through each due flow
4. THE DataFlowsController SHALL delegate execution to the FlowExecutor service
5. THE DataFlowsController SHALL count the number of flows triggered

### Requirement 5: Response Format

**User Story:** As an external scheduler, I want a JSON response with execution summary, so that I can monitor heartbeat results

#### Acceptance Criteria

1. THE DataFlowsController SHALL return a JSON response
2. THE response SHALL include a flows_due integer field
3. THE response SHALL include a flows_triggered integer field
4. THE response SHALL include a timestamp string field in ISO 8601 format
5. THE DataFlowsController SHALL return HTTP 200 OK for successful requests

### Requirement 6: Error Handling

**User Story:** As a developer, I want proper error handling, so that failures are logged and reported appropriately

#### Acceptance Criteria

1. WHEN authentication fails, THE DataFlowsController SHALL log the failure with request details
2. WHEN IP whitelisting fails, THE DataFlowsController SHALL log the rejected IP address
3. WHEN a database error occurs, THE DataFlowsController SHALL return HTTP 500 Internal Server Error
4. WHEN an unexpected error occurs, THE DataFlowsController SHALL log the full backtrace
5. THE DataFlowsController SHALL not expose sensitive error details in the response

### Requirement 7: CSRF Protection

**User Story:** As a developer, I want CSRF protection bypassed for the heartbeat endpoint, so that external API calls work without tokens

#### Acceptance Criteria

1. THE DataFlowsController SHALL use skip_before_action for verify_authenticity_token
2. THE skip_before_action SHALL apply only to the heartbeat action
3. THE DataFlowsController SHALL rely on authentication token and IP whitelisting for security
4. THE DataFlowsController SHALL not require a CSRF token in the request
5. THE DataFlowsController SHALL document the security model in comments

### Requirement 8: Logging

**User Story:** As a developer, I want comprehensive logging, so that I can monitor and debug heartbeat requests

#### Acceptance Criteria

1. THE DataFlowsController SHALL log each heartbeat request with timestamp
2. THE DataFlowsController SHALL log the number of flows due and triggered
3. THE DataFlowsController SHALL log authentication failures with request IP
4. THE DataFlowsController SHALL log IP whitelisting rejections
5. THE DataFlowsController SHALL use Rails logger with appropriate log levels

### Requirement 9: Routes Configuration

**User Story:** As a developer, I want the heartbeat route configured, so that the endpoint is accessible at the correct path

#### Acceptance Criteria

1. THE Heartbeat Runtime SHALL define a route for POST /data_flows/heartbeat
2. THE route SHALL map to DataFlowsController#heartbeat
3. THE route SHALL be namespaced appropriately
4. THE route SHALL be accessible via the configured path
5. THE route SHALL not define any other HTTP methods for the heartbeat endpoint
