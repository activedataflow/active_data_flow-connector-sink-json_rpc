# Rails Heartbeat App - Requirements Overview

## Introduction

The Rails Heartbeat App is a Rails Engine gem that provides scheduled data flow execution capabilities through an HTTP heartbeat endpoint. It allows external schedulers to trigger execution of configured data flows at specified intervals, with built-in security features including token authentication and IP whitelisting.

## System Architecture

The system consists of six major feature areas:

1. **Configuration Management** - Centralized configuration for security and endpoint settings
2. **Data Flow Models** - ActiveRecord models for managing flows and tracking execution runs
3. **Heartbeat Endpoint** - HTTP endpoint for triggering flow executions
4. **Flow Execution Service** - Service layer for orchestrating flow execution lifecycle
5. **Install Generator** - Rails generator for automated gem installation
6. **Rails Engine Integration** - Engine infrastructure for seamless Rails integration

## Feature Specifications

Each feature has detailed requirements documented in its respective subdirectory:

- `configuration-management/requirements.md` - Configuration system with authentication, IP whitelisting, and endpoint customization
- `data-flow-models/requirements.md` - DataFlow and DataFlowRun models with validations, associations, and scheduling logic
- `heartbeat-endpoint/requirements.md` - HTTP endpoint with security measures and error handling
- `flow-execution-service/requirements.md` - Service for executing flows and tracking status
- `install-generator/requirements.md` - Rails generator for database migrations and initializer setup
- `rails-engine-integration/requirements.md` - Engine configuration for namespace isolation and component loading

## Key Capabilities

### Security
- Token-based authentication for heartbeat requests
- IP whitelisting to restrict access by source address
- Secure token comparison to prevent timing attacks
- CSRF protection bypass for external API access

### Scheduling
- Configurable run intervals for each data flow
- Automatic detection of flows due to run
- Pessimistic locking to prevent concurrent execution
- Last run tracking with status and timestamp

### Execution Tracking
- Complete execution history with DataFlowRun records
- Status tracking (pending, in_progress, success, failed)
- Error message and backtrace capture for failures
- Execution duration calculation

### Developer Experience
- Simple configuration DSL
- Rails generator for one-command installation
- Namespace isolation to prevent conflicts
- Automatic component loading via Rails Engine

## Technology Stack

- Ruby on Rails (Engine)
- ActiveRecord for data persistence
- ActionController for HTTP endpoint
- Rails Generators for installation automation

## Version

Current version: 0.1.1
