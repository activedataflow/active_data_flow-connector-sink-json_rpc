# ActiveDataFlow Core - Requirements Document

## Introduction

This document specifies the requirements for the `active_data_flow` core gem, which provides abstract interfaces and base classes for distributed stream processing. The core gem is implementation-independent and defines the contracts that runtime and connector implementations must follow.

The core gem is extended by the following subcomponent gems:

**Framework Extensions:**
- `active_data_flow-source_support` - Flink-inspired split-based source architecture

**Runtime Implementations:**
- `active_data_flow-rails_heartbeat_app` - Synchronous execution in Rails app process
- `active_data_flow-rails_heartbeat_job` - Asynchronous execution via ActiveJob
- `active_data_flow-aws_lambda` - Serverless execution on AWS Lambda
- `active_data_flow-flink` - Distributed execution on Apache Flink

**Connector Implementations:**
- `active_data_flow-rafka` - Kafka-compatible Redis streams source/sink
- `active_data_flow-active_record` - Rails database table sink
- `active_data_flow-cache` - Rails cache sink
- `active_data_flow-file` - File source/sink (CSV, JSON)
- `active_data_flow-iceberg` - Apache Iceberg table source/sink

## Glossary

- **ActiveDataFlow**: The core Ruby gem providing abstract interfaces and base classes
- **DataFlow**: An orchestrator class that coordinates data movement and transformation
- **Source**: An abstraction for reading data from external systems
- **Sink**: An abstraction for writing data to external systems
- **Runtime**: The execution environment for DataFlows
- **Plugin**: A separate gem that extends ActiveDataFlow with concrete implementations
- **Subcomponent**: A gem that depends on and extends the core gem

## Requirements

### Requirement 1: Source Base Class

**User Story:** As a connector developer, I want a Source base class, so that I can implement custom data sources with a consistent interface.

#### Acceptance Criteria

1. THE ActiveDataFlow SHALL provide an ActiveDataFlow::Source base class
2. THE ActiveDataFlow::Source SHALL define an `initialize(configuration)` method
3. THE ActiveDataFlow::Source SHALL define an abstract `each` method that yields records
4. THE ActiveDataFlow::Source SHALL define a `configuration_attributes` class method
5. THE ActiveDataFlow::Source SHALL raise NotImplementedError when abstract methods are not overridden

### Requirement 2: Sink Base Class

**User Story:** As a connector developer, I want a Sink base class, so that I can implement custom data sinks with a consistent interface.

#### Acceptance Criteria

1. THE ActiveDataFlow SHALL provide an ActiveDataFlow::Sink base class
2. THE ActiveDataFlow::Sink SHALL define an `initialize(configuration)` method
3. THE ActiveDataFlow::Sink SHALL define an abstract `write(record)` method
4. THE ActiveDataFlow::Sink SHALL define a `configuration_attributes` class method
5. THE ActiveDataFlow::Sink SHALL raise NotImplementedError when abstract methods are not overridden

### Requirement 3: DataFlow Module

**User Story:** As a developer, I want a DataFlow module, so that I can create orchestrator classes that coordinate data processing.

#### Acceptance Criteria

1. THE ActiveDataFlow SHALL provide an ActiveDataFlow::DataFlow module
2. THE ActiveDataFlow::DataFlow SHALL provide an `initialize(configuration)` method when included
3. THE ActiveDataFlow::DataFlow SHALL allow classes to define `configuration_attributes`
4. THE ActiveDataFlow::DataFlow SHALL provide access to configuration through instance variables
5. THE ActiveDataFlow::DataFlow SHALL define an abstract `run` method

### Requirement 4: Plugin Registry System

**User Story:** As a gem maintainer, I want a plugin registry, so that runtime and connector gems can register themselves automatically.

#### Acceptance Criteria

1. THE ActiveDataFlow SHALL provide an ActiveDataFlow::Registry class
2. THE ActiveDataFlow::Registry SHALL support registering source implementations by type name
3. THE ActiveDataFlow::Registry SHALL support registering sink implementations by type name
4. THE ActiveDataFlow::Registry SHALL support registering runtime implementations by type name
5. THE ActiveDataFlow::Registry SHALL provide lookup methods for registered components

### Requirement 5: Configuration Validation

**User Story:** As a developer, I want configuration validation, so that I catch errors early before execution.

#### Acceptance Criteria

1. THE ActiveDataFlow SHALL provide an ActiveDataFlow::Configuration class
2. THE ActiveDataFlow::Configuration SHALL validate required attributes are present
3. THE ActiveDataFlow::Configuration SHALL validate attribute types match expectations
4. THE ActiveDataFlow::Configuration SHALL provide helpful error messages for invalid configurations
5. THE ActiveDataFlow::Configuration SHALL support nested configuration objects

### Requirement 6: Error Handling Framework

**User Story:** As a developer, I want consistent error handling, so that I can handle failures gracefully across all implementations.

#### Acceptance Criteria

1. THE ActiveDataFlow SHALL define custom exception classes for common errors
2. THE ActiveDataFlow SHALL provide ActiveDataFlow::ConfigurationError for config issues
3. THE ActiveDataFlow SHALL provide ActiveDataFlow::SourceError for source failures
4. THE ActiveDataFlow SHALL provide ActiveDataFlow::SinkError for sink failures
5. THE ActiveDataFlow SHALL provide ActiveDataFlow::RuntimeError for execution failures

### Requirement 7: Logging Interface

**User Story:** As a developer, I want a logging interface, so that I can debug and monitor DataFlow execution.

#### Acceptance Criteria

1. THE ActiveDataFlow SHALL provide an ActiveDataFlow::Logger interface
2. THE ActiveDataFlow SHALL support standard log levels (debug, info, warn, error)
3. THE ActiveDataFlow SHALL allow loggers to be configured per DataFlow
4. THE ActiveDataFlow SHALL include contextual information in log messages
5. THE ActiveDataFlow SHALL support structured logging with key-value pairs

### Requirement 8: Version Compatibility

**User Story:** As a gem maintainer, I want version compatibility checks, so that incompatible plugins are detected early.

#### Acceptance Criteria

1. THE ActiveDataFlow SHALL define a version constant
2. THE ActiveDataFlow SHALL provide a compatibility check method for plugins
3. WHEN a plugin is loaded, THE ActiveDataFlow SHALL verify version compatibility
4. THE ActiveDataFlow SHALL raise an error for incompatible plugin versions
5. THE ActiveDataFlow SHALL support semantic versioning for compatibility checks

### Requirement 9: Subcomponent Integration

**User Story:** As a gem maintainer, I want seamless subcomponent integration, so that runtime and connector gems work together correctly.

#### Acceptance Criteria

1. THE ActiveDataFlow SHALL provide a registration API for subcomponents
2. THE ActiveDataFlow SHALL validate subcomponent dependencies on core version
3. THE ActiveDataFlow SHALL allow subcomponents to extend core functionality
4. THE ActiveDataFlow SHALL maintain a registry of loaded subcomponents
5. THE ActiveDataFlow SHALL provide introspection of available runtimes and connectors
