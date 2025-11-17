# Requirements Document

## Introduction

The Rails Engine Integration feature provides a Rails Engine that integrates the heartbeat app functionality into host Rails applications, including namespace isolation, generator configuration, and automatic path loading.

## Glossary

- **Rails Engine**: A miniature Rails application that provides functionality to host applications
- **Namespace Isolation**: A mechanism that prevents naming conflicts between the engine and host application
- **Eager Loading**: A Rails mechanism that loads code at application startup rather than on-demand
- **Generator Configuration**: Settings that control how Rails generators behave within the engine
- **Application Paths**: Directories that Rails searches for models, controllers, and other components

## Requirements

### Requirement 1

**User Story:** As a Rails developer, I want the gem to integrate as an engine, so that it works seamlessly with my Rails application

#### Acceptance Criteria

1. THE Rails Engine SHALL inherit from Rails::Engine
2. THE Rails Engine SHALL be defined in the ActiveDataFlow::RailsHeartbeatApp module
3. THE Rails Engine SHALL isolate its namespace using `isolate_namespace`
4. THE Rails Engine SHALL use ActiveDataFlow::RailsHeartbeatApp as the isolated namespace
5. THE Rails Engine SHALL be automatically loaded when the gem is required

### Requirement 2

**User Story:** As a Rails developer, I want generators configured for RSpec, so that generated test files use my preferred testing framework

#### Acceptance Criteria

1. THE Rails Engine SHALL configure generators in a config.generators block
2. THE Rails Engine SHALL set the test framework to :rspec
3. WHEN generators are run within the engine, THE Rails Engine SHALL use RSpec for test file generation
4. THE Rails Engine SHALL apply generator configuration during engine initialization
5. THE Rails Engine SHALL not override host application generator settings for non-engine code

### Requirement 3

**User Story:** As a Rails developer, I want engine components automatically loaded, so that models, controllers, and services are available without manual requires

#### Acceptance Criteria

1. THE Rails Engine SHALL add app/models to the application paths with eager loading enabled
2. THE Rails Engine SHALL add app/controllers to the application paths with eager loading enabled
3. THE Rails Engine SHALL add app/services to the application paths with eager loading enabled
4. THE Rails Engine SHALL configure paths in an initializer block
5. WHEN the Rails application starts, THE Rails Engine SHALL load all components from the configured paths

### Requirement 4

**User Story:** As a Rails developer, I want the engine initialized at the right time, so that it integrates properly with the Rails boot process

#### Acceptance Criteria

1. THE Rails Engine SHALL use an initializer named "active_data_flow_rails_heartbeat_app.load_app_paths"
2. THE Rails Engine SHALL receive the host application instance in the initializer block
3. THE Rails Engine SHALL configure paths on the host application's config object
4. THE Rails Engine SHALL run the initializer during the Rails initialization phase
5. THE Rails Engine SHALL complete initialization before the application is ready to serve requests

### Requirement 5

**User Story:** As a gem maintainer, I want namespace isolation, so that the engine's classes don't conflict with host application classes

#### Acceptance Criteria

1. THE Rails Engine SHALL isolate all controllers within the ActiveDataFlow::RailsHeartbeatApp namespace
2. THE Rails Engine SHALL isolate all models within the ActiveDataFlow::RailsHeartbeatApp namespace
3. THE Rails Engine SHALL isolate all services within the ActiveDataFlow::RailsHeartbeatApp namespace
4. THE Rails Engine SHALL generate routes under the isolated namespace
5. THE Rails Engine SHALL prevent naming conflicts with host application classes
