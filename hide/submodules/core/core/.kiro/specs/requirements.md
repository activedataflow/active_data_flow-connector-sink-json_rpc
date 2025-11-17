# ActiveDataFlow Core - Requirements Document

## Introduction

ActiveDataFlow Core is a modular stream processing framework for Ruby that provides abstract interfaces and base classes for building pluggable data processing pipelines. The system enables developers to create custom data sources, sinks, and processing flows with a plugin-based architecture, supporting multiple message formats including unconstrained messages, CloudEvents, and CloudEvents with Linked Data extensions.

## Glossary

- **System**: The ActiveDataFlow Core gem
- **Source**: A component that produces data messages for processing
- **Sink**: A component that consumes and writes data messages to a destination
- **DataFlow**: An orchestration component that coordinates data movement from sources through transformations to sinks
- **Registry**: A central repository that manages registered sources, sinks, and runtime implementations
- **Message**: A typed data container that flows through the system
- **Configuration**: A validated set of key-value pairs that define component behavior
- **Plugin**: An external gem that extends the System with custom sources, sinks, or runtimes
- **Developer**: A user who creates custom sources, sinks, or data flows using the System
- **CloudEvent**: A standardized message format following the CloudEvents specification
- **Subcomponent**: A registered plugin gem with version information

## Requirements

### Requirement 1: Source Component Management

**User Story:** As a developer, I want to create custom data sources that produce messages, so that I can integrate various data providers into my processing pipeline.

#### Acceptance Criteria

1.1 THE System SHALL provide a base Source class that developers can inherit from

1.2 WHEN a developer creates a Source subclass, THE System SHALL require the subclass to implement an each method that yields messages

1.3 THE System SHALL provide a configuration_attributes class method that Source subclasses can override to declare their configuration schema

1.4 WHEN a Source is instantiated with a configuration hash, THE System SHALL validate the configuration against the declared attributes

1.5 IF a required configuration attribute is missing, THEN THE System SHALL raise a ConfigurationError with a descriptive message

### Requirement 2: Sink Component Management

**User Story:** As a developer, I want to create custom data sinks that write messages to destinations, so that I can output processed data to various storage systems.

#### Acceptance Criteria

2.1 THE System SHALL provide a base Sink class that developers can inherit from

2.2 WHEN a developer creates a Sink subclass, THE System SHALL require the subclass to implement a write method that accepts a single message

2.3 THE System SHALL provide optional flush and close methods that Sink subclasses can override for resource management

2.4 THE System SHALL provide a configuration_attributes class method that Sink subclasses can override to declare their configuration schema

2.5 WHEN a Sink is instantiated with a configuration hash, THE System SHALL validate the configuration against the declared attributes

### Requirement 3: DataFlow Orchestration

**User Story:** As a developer, I want to orchestrate data processing flows that connect sources to sinks with transformations, so that I can build complete data pipelines.

#### Acceptance Criteria

3.1 THE System SHALL provide a DataFlow module that developers can include in their flow classes

3.2 WHEN a DataFlow class is created, THE System SHALL require the class to implement a run method

3.3 THE System SHALL provide a configuration_attributes class method that DataFlow classes can override to declare their configuration schema

3.4 WHEN a DataFlow is instantiated with a configuration hash, THE System SHALL validate the configuration against the declared attributes

3.5 THE System SHALL provide a logger instance to DataFlow classes for structured logging

### Requirement 4: Plugin Registry

**User Story:** As a developer, I want to register and discover available sources, sinks, and runtimes, so that I can dynamically instantiate components by type identifier.

#### Acceptance Criteria

4.1 THE System SHALL provide a Registry that accepts source registrations with a type symbol and class

4.2 THE System SHALL provide a Registry that accepts sink registrations with a type symbol and class

4.3 THE System SHALL provide a Registry that accepts runtime registrations with a type symbol and class

4.4 WHEN a source is registered, THE System SHALL validate that the class inherits from the Source base class

4.5 WHEN a sink is registered, THE System SHALL validate that the class inherits from the Sink base class

4.6 WHEN a developer looks up a source by type, THE System SHALL return the registered source class

4.7 WHEN a developer looks up a sink by type, THE System SHALL return the registered sink class

4.8 IF a requested type is not registered, THEN THE System SHALL raise a ConfigurationError listing available types

4.9 THE System SHALL provide methods to list all available source types

4.10 THE System SHALL provide methods to list all available sink types

4.11 THE System SHALL provide methods to list all available runtime types

### Requirement 5: Configuration Validation

**User Story:** As a developer, I want my component configurations to be validated automatically, so that I can catch configuration errors early with clear error messages.

#### Acceptance Criteria

5.1 THE System SHALL provide a Configuration class that accepts a values hash and attributes definition

5.2 WHEN a Configuration is created, THE System SHALL validate that all non-optional attributes are present

5.3 IF a required attribute is missing, THEN THE System SHALL raise a ConfigurationError identifying the missing attribute

5.4 WHEN a Configuration is created, THE System SHALL validate that attribute values match their declared types

5.5 THE System SHALL support string, integer, boolean, hash, and array type validations

5.6 IF an attribute value has an incorrect type, THEN THE System SHALL raise a ConfigurationError specifying the expected and actual types

5.7 THE System SHALL provide hash-like access to configuration values using bracket notation

5.8 THE System SHALL provide a to_h method that returns a duplicate of the configuration hash

### Requirement 6: Message Type Support

**User Story:** As a developer, I want to work with multiple message formats including unconstrained data, CloudEvents, and CloudEvents with Linked Data, so that I can integrate with various messaging standards.

#### Acceptance Criteria

6.1 THE System SHALL provide an Unconstrained message type that accepts any Ruby object as data

6.2 WHEN an Unconstrained message is converted to a hash, THE System SHALL return the data if it is a hash, or wrap non-hash data in a value key

6.3 THE System SHALL provide a CloudEvent message type that enforces required attributes: id, source, specversion, and type

6.4 WHEN a CloudEvent is created without a required attribute, THE System SHALL raise a ConfigurationError identifying the missing attribute

6.5 THE System SHALL support optional CloudEvent attributes including datacontenttype, dataschema, subject, time, data, and data_base64

6.6 THE System SHALL provide a CloudEventLd message type that extends CloudEvent with Linked Data support

6.7 WHEN a CloudEventLd is created without a @context attribute, THE System SHALL raise a ConfigurationError

6.8 THE System SHALL provide hash-like access to CloudEvent attributes using bracket notation

6.9 THE System SHALL provide a to_h method that returns all CloudEvent attributes as a hash

### Requirement 7: Convenience Methods

**User Story:** As a developer, I want convenient factory methods to create sources and sinks from the registry, so that I can write concise pipeline code.

#### Acceptance Criteria

7.1 THE System SHALL provide a module-level source method that accepts a type symbol and configuration hash

7.2 WHEN the source method is called, THE System SHALL look up the source class in the Registry and return a new instance

7.3 THE System SHALL provide a module-level sink method that accepts a type symbol and configuration hash

7.4 WHEN the sink method is called, THE System SHALL look up the sink class in the Registry and return a new instance

### Requirement 8: Subcomponent Version Management

**User Story:** As a plugin developer, I want to register my plugin gem with version information, so that the system can track installed plugins and their versions.

#### Acceptance Criteria

8.1 THE System SHALL provide a method to register subcomponents with a name and version string

8.2 THE System SHALL store registered subcomponent names and versions in the Registry

8.3 THE System SHALL provide a method to list all registered subcomponents with their versions

### Requirement 9: Structured Logging

**User Story:** As a developer, I want to use structured logging in my data flows, so that I can debug and monitor pipeline execution with contextual information.

#### Acceptance Criteria

9.1 THE System SHALL provide a Logger that creates logger instances for named components

9.2 THE System SHALL allow developers to configure a custom logging backend

9.3 WHEN a DataFlow is instantiated, THE System SHALL provide a logger instance scoped to the DataFlow class name

9.4 THE System SHALL support standard log levels including info, debug, and error
