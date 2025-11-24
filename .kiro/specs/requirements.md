# Requirements Document

## Introduction

This document specifies the requirements for a Ruby gem called `active_data_flow` that provides stream processing patterns for Rails applications. The core gem defines abstract interfaces and base classes, while concrete implementations are provided in separate gems (submodules).

The `active_data_flow` gem provides:
- Abstract Source/Sink/Runtime interfaces for pluggable components
- Rails engine integration for DataFlow management
- Heartbeat-based execution runtime
- ActiveRecord connector implementations

## Glossary

- **ActiveDataFlow**: The Ruby module namespace for the gem
- **Source**: A component that reads data from external systems
- **Sink**: A component that writes data to external systems
- **Runtime**: An execution environment for DataFlows
- **DataFlow**: An orchestration that reads from sources, transforms data, and writes to sinks
- **Heartbeat**: A periodic REST endpoint trigger for autonomous execution
- **Connector**: A source or sink implementation for a specific external system

## Requirements

### Requirement 1: Base Source and Sink Abstractions

**User Story:** As a developer, I want pluggable source and sink abstractions, so that I can decouple my DataFlow logic from specific external systems and easily reconfigure pipelines.

#### Acceptance Criteria

1. THE ActiveDataFlow SHALL provide a base `Connector::Source` class with an `each` method that yields records
2. THE ActiveDataFlow SHALL provide a base `Connector::Sink` class with a `write` method that accepts records
3. WHEN a Source is initialized, THE ActiveDataFlow SHALL accept a configuration hash
4. WHEN a Sink is initialized, THE ActiveDataFlow SHALL accept a configuration hash
5. THE ActiveDataFlow SHALL allow subclasses to define their required configuration attributes

### Requirement 2: Message Types

**User Story:** As a developer, I want standardized message types, so that I can pass data consistently between sources, transforms, and sinks.

#### Acceptance Criteria

1. THE ActiveDataFlow SHALL provide a `Message::Typed` class for messages with schema validation
2. THE ActiveDataFlow SHALL provide a `Message::Untyped` class for flexible data handling
3. THE ActiveDataFlow SHALL allow sources to yield message instances
4. THE ActiveDataFlow SHALL allow sinks to accept message instances
5. THE ActiveDataFlow SHALL allow DataFlows to work with both typed and untyped messages

### Requirement 3: ActiveRecord Connector Implementation

**User Story:** As a developer, I want ready-to-use ActiveRecord connectors, so that I can quickly integrate database tables as sources and sinks.

#### Acceptance Criteria

1. THE ActiveDataFlow SHALL provide a `Connector::Source::ActiveRecord` class for reading from database tables
2. THE ActiveDataFlow SHALL provide a `Connector::Sink::ActiveRecord` class for writing to database tables
3. WHEN using ActiveRecord source, THE ActiveDataFlow SHALL accept a model name configuration
4. WHEN using ActiveRecord sink, THE ActiveDataFlow SHALL accept a model name configuration
5. THE ActiveDataFlow SHALL handle database errors gracefully in connector implementations

### Requirement 4: Runtime Base Class

**User Story:** As a developer, I want a runtime abstraction, so that I can implement different execution environments for DataFlows.

#### Acceptance Criteria

1. THE ActiveDataFlow SHALL provide a base `Runtime` class for execution environments
2. THE ActiveDataFlow SHALL provide a `Runtime::Runner` base class for executing DataFlows
3. THE ActiveDataFlow SHALL allow runtime implementations to define their execution strategy
4. THE ActiveDataFlow SHALL support configuration of runtime parameters
5. THE ActiveDataFlow SHALL allow multiple runtime implementations to coexist

### Requirement 5: Heartbeat Runtime Implementation

**User Story:** As a developer, I want a heartbeat-based runtime, so that I can execute DataFlows on a schedule without complex job schedulers.

#### Acceptance Criteria

1. THE ActiveDataFlow SHALL provide a `Runtime::Heartbeat` implementation
2. THE ActiveDataFlow SHALL provide a `Runtime::Heartbeat::Runner` for executing DataFlows
3. THE ActiveDataFlow SHALL support periodic execution via REST endpoint triggers
4. THE ActiveDataFlow SHALL support configurable execution intervals
5. THE ActiveDataFlow SHALL handle runtime errors gracefully with logging

### Requirement 6: Rails Engine Integration

**User Story:** As a Rails developer, I want ActiveDataFlow integrated as a Rails engine, so that I can manage DataFlows within my Rails application.

#### Acceptance Criteria

1. THE ActiveDataFlow SHALL provide a Rails engine for integration
2. THE ActiveDataFlow SHALL provide controllers for DataFlow management
3. THE ActiveDataFlow SHALL provide views for DataFlow monitoring
4. THE ActiveDataFlow SHALL provide routes for heartbeat endpoints
5. THE ActiveDataFlow SHALL integrate with Rails conventions (models, migrations, etc.)

### Requirement 7: DataFlow Orchestration

**User Story:** As a developer, I want a DataFlow base class, so that I can focus on transformation logic while the framework handles source/sink coordination.

#### Acceptance Criteria

1. THE ActiveDataFlow SHALL provide a DataFlow base class for orchestration
2. THE ActiveDataFlow SHALL allow DataFlows to configure sources and sinks
3. WHEN a DataFlow runs, THE ActiveDataFlow SHALL instantiate configured sources and sinks
4. THE ActiveDataFlow SHALL provide a run method that orchestrates read-transform-write loops
5. THE ActiveDataFlow SHALL allow DataFlows to implement custom transformation logic

### Requirement 8: Modular Gem Architecture

**User Story:** As a gem maintainer, I want a modular architecture with submodules, so that components can be developed and versioned independently in separate repositories.

#### Acceptance Criteria

1. THE ActiveDataFlow core gem SHALL define abstract base classes in `lib/` as placeholders
2. THE ActiveDataFlow SHALL organize concrete implementations in `submodules/` directory as separate git repositories
3. THE ActiveDataFlow SHALL allow each submodule to have its own gemspec for independent versioning
4. THE ActiveDataFlow SHALL allow submodules to be published as separate gems with independent git history
5. THE ActiveDataFlow SHALL maintain a clear separation between core abstractions and submodule implementations
