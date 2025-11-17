# Requirements Document

## Introduction

This document specifies the requirements for a Ruby gem called `active_data_flow` that provides distributed stream processing patterns based on Apache Flink's architecture. The core gem defines abstract interfaces and base classes, while concrete implementations are provided in separate gems managed as submodules.

The `active_data_flow` gem is implementation-independent and provides:
- Abstract Source/Sink interfaces for pluggable data connectors
- Flink-inspired source architecture with split enumeration
- DataFlow orchestration patterns

**User Story:** As a developer, I want pluggable source and sink abstractions, so that I can decouple my DataFlow logic from specific external systems and easily reconfigure pipelines.

#### Acceptance Criteria

1. THE ActiveDataFlow SHALL provide a base Source class with an `each` method that yields records
2. THE ActiveDataFlow SHALL provide a base Sink class with a `write` method that accepts records
3. WHEN a Source is initialized, THE ActiveDataFlow SHALL accept a configuration hash
4. WHEN a Sink is initialized, THE ActiveDataFlow SHALL accept a configuration hash
5. THE ActiveDataFlow SHALL allow subclasses to define their required configuration attributes

### Requirement 2: Concrete Source Implementations

**User Story:** As a developer, I want ready-to-use source implementations, so that I can quickly integrate common data sources without writing boilerplate code.

#### Acceptance Criteria

1. THE ActiveDataFlow SHALL provide a Rafka source for reading from Redis streams
2. THE ActiveDataFlow SHALL provide a File source for reading CSV and JSON files
3. WHEN using Rafka source, THE ActiveDataFlow SHALL support consumer groups and stream names
4. WHEN using File source, THE ActiveDataFlow SHALL support multiple file formats
5. THE ActiveDataFlow SHALL allow each source implementation to define its specific configuration needs

### Requirement 3: Concrete Sink Implementations

**User Story:** As a developer, I want ready-to-use sink implementations, so that I can write data to common destinations without custom integration code.

#### Acceptance Criteria

1. THE ActiveDataFlow SHALL provide an ActiveRecord sink for writing to database tables
2. THE ActiveDataFlow SHALL provide a Cache sink for writing to Rails cache
3. WHEN using ActiveRecord sink, THE ActiveDataFlow SHALL accept a model name configuration
4. WHEN using Cache sink, THE ActiveDataFlow SHALL support TTL and key attribute configuration
5. THE ActiveDataFlow SHALL handle write errors gracefully in sink implementations

### Requirement 4: Flink-Inspired Source Architecture

**User Story:** As a developer, I want a Flink-style source architecture with split enumeration, so that I can build scalable parallel data ingestion with work distribution.

#### Acceptance Criteria

1. THE ActiveDataFlow SHALL provide a Source factory class for creating enumerators and readers
2. THE ActiveDataFlow SHALL provide a Split interface with a unique split_id method
3. THE ActiveDataFlow SHALL provide a SplitEnumerator base class for discovering and assigning splits
4. THE ActiveDataFlow SHALL provide a SourceReader base class for reading from assigned splits
5. THE ActiveDataFlow SHALL support both bounded and unbounded source types

### Requirement 5: Split Enumeration and Assignment

**User Story:** As a developer, I want automatic split discovery and assignment, so that work is distributed efficiently across parallel readers.

#### Acceptance Criteria

1. WHEN a SplitEnumerator starts, THE ActiveDataFlow SHALL discover available splits
2. WHEN a SourceReader registers, THE ActiveDataFlow SHALL assign splits to that reader
3. THE ActiveDataFlow SHALL provide a SplitEnumeratorContext for split assignment operations
4. THE ActiveDataFlow SHALL provide a SourceReaderContext for split request operations
5. WHEN a reader completes a split, THE ActiveDataFlow SHALL allow it to request another split

### Requirement 6: Concrete Split-Based Source Implementations

**User Story:** As a developer, I want split-based implementations for common sources, so that I can leverage parallel processing for high-throughput ingestion.

#### Acceptance Criteria

1. THE ActiveDataFlow SHALL provide RafkaSplit for representing Rafka stream partitions
2. THE ActiveDataFlow SHALL provide RafkaSplitEnumerator for discovering Rafka partitions
3. THE ActiveDataFlow SHALL provide RafkaSourceReader for reading from Rafka partitions
4. THE ActiveDataFlow SHALL provide FileSplit for representing individual files
5. THE ActiveDataFlow SHALL provide FileSplitEnumerator and FileSourceReader for file processing

### Requirement 7: Heartbeat-Based Execution System

**User Story:** As a system operator, I want a heartbeat-triggered execution model, so that I can schedule DataFlows reliably without complex background job schedulers.

#### Acceptance Criteria

1. THE ActiveDataFlow SHALL provide a data_flows database table for storing flow configurations
2. THE ActiveDataFlow SHALL provide a data_flow_runs table for logging execution history
3. THE ActiveDataFlow SHALL provide a heartbeat endpoint that identifies due DataFlows
4. WHEN a DataFlow is due, THE ActiveDataFlow SHALL update its last_run_at timestamp
5. THE ActiveDataFlow SHALL enqueue a background job to execute the DataFlow asynchronously

### Requirement 8: DataFlow Scheduling and Status Management

**User Story:** As a developer, I want configurable scheduling intervals, so that my DataFlows run automatically at the appropriate frequency.

#### Acceptance Criteria

1. THE ActiveDataFlow SHALL support a run_interval field for specifying execution frequency
2. THE ActiveDataFlow SHALL provide a due_to_run scope for querying flows ready to execute
3. WHEN querying due flows, THE ActiveDataFlow SHALL use database locking to prevent race conditions
4. THE ActiveDataFlow SHALL track last_run_status as success, failed, or in_progress
5. THE ActiveDataFlow SHALL store error messages and backtraces for failed runs

### Requirement 9: DataFlow Execution Job

**User Story:** As a developer, I want asynchronous DataFlow execution, so that long-running flows don't block the heartbeat endpoint.

#### Acceptance Criteria

1. THE ActiveDataFlow SHALL provide a DataFlowRunJob for executing flows
2. WHEN a job starts, THE ActiveDataFlow SHALL create a DataFlowRun log entry
3. THE ActiveDataFlow SHALL instantiate the DataFlow class from its name
4. WHEN execution succeeds, THE ActiveDataFlow SHALL update status to success with end timestamp
5. IF execution fails, THEN THE ActiveDataFlow SHALL record error details and re-raise the exception

### Requirement 10: DataFlow Orchestration

**User Story:** As a developer, I want a DataFlow base class, so that I can focus on transformation logic while the framework handles source/sink coordination.

#### Acceptance Criteria

1. THE ActiveDataFlow SHALL provide a DataFlow module for inclusion in flow classes
2. THE ActiveDataFlow SHALL allow DataFlows to define configuration_attributes
3. WHEN a DataFlow runs, THE ActiveDataFlow SHALL instantiate configured sources and sinks
4. THE ActiveDataFlow SHALL provide a run method that orchestrates read-transform-write loops
5. THE ActiveDataFlow SHALL allow DataFlows to implement custom transformation logic

### Requirement 11: Security and Access Control

**User Story:** As a system operator, I want secure heartbeat endpoints, so that unauthorized users cannot trigger DataFlow executions.

#### Acceptance Criteria

1. THE ActiveDataFlow SHALL provide authentication mechanisms for the heartbeat endpoint
2. THE ActiveDataFlow SHALL support IP whitelisting for heartbeat requests
3. THE ActiveDataFlow SHALL support authentication tokens in request headers
4. THE ActiveDataFlow SHALL log all heartbeat requests with timestamps
5. THE ActiveDataFlow SHALL return appropriate HTTP status codes for unauthorized access

### Requirement 12: Dynamic Configuration

**User Story:** As a developer, I want to reconfigure DataFlows without code changes, so that I can adapt pipelines to changing requirements.

#### Acceptance Criteria

1. THE ActiveDataFlow SHALL store source and sink configurations as JSONB in the database
2. THE ActiveDataFlow SHALL support changing source types through configuration updates
3. THE ActiveDataFlow SHALL support changing sink types through configuration updates
4. WHEN configuration changes, THE ActiveDataFlow SHALL apply new settings on next execution
5. THE ActiveDataFlow SHALL validate configuration structure before saving

### Requirement 13: Modular Gem Architecture

**User Story:** As a gem maintainer, I want a modular architecture with separate gems, so that users can install only the components they need.

#### Acceptance Criteria

1. THE ActiveDataFlow core gem SHALL define abstract base classes and interfaces only
2. THE ActiveDataFlow core gem SHALL NOT include concrete runtime or connector implementations
3. THE ActiveDataFlow SHALL provide a plugin registration mechanism for runtimes
4. THE ActiveDataFlow SHALL provide a plugin registration mechanism for sources and sinks
5. THE ActiveDataFlow SHALL support loading implementations from separate gems

### Requirement 14: Runtime Plugin System

**User Story:** As a developer, I want to choose my DataFlow runtime, so that I can deploy flows in the environment that best suits my needs.

#### Acceptance Criteria

1. THE ActiveDataFlow SHALL provide a Runtime base class for execution environments
2. THE ActiveDataFlow SHALL allow runtime gems to register themselves
3. WHEN a DataFlow is configured, THE ActiveDataFlow SHALL accept a runtime type parameter
4. THE ActiveDataFlow SHALL instantiate the appropriate runtime based on configuration
5. THE ActiveDataFlow SHALL support multiple runtimes in the same application

### Requirement 15: Connector Plugin System

**User Story:** As a developer, I want to add custom sources and sinks, so that I can integrate with any external system.

#### Acceptance Criteria

1. THE ActiveDataFlow SHALL provide a connector registry for sources and sinks
2. WHEN a connector gem is loaded, THE ActiveDataFlow SHALL auto-register its components
3. THE ActiveDataFlow SHALL resolve source and sink classes by type name
4. THE ActiveDataFlow SHALL validate that required connector gems are installed
5. THE ActiveDataFlow SHALL provide helpful error messages for missing connectors
