# ActiveDataFlow Glossary

This glossary defines terms used throughout the ActiveDataFlow project documentation.

## Core Concepts

- **ActiveDataFlow**: The Ruby module namespace for the gem; a modular stream processing framework for Ruby
- **Source**: A component that reads data from external systems
- **Sink**: A component that writes data to external systems
- **Runtime**: An execution environment for DataFlows
- **DataFlow**: An orchestration that reads from sources, transforms data, and writes to sinks; the model representing a data pipeline configuration
- **DataFlowRun**: The model representing an execution instance of a DataFlow
- **Heartbeat**: A periodic REST endpoint trigger for autonomous execution
- **Connector**: A source or sink implementation for a specific external system
- **Message**: A data container passed between sources, transforms, and sinks

## Storage Backends

- **Storage Backend**: The persistence layer used to store DataFlow and DataFlowRun records
- **ActiveRecord Backend** (`:active_record`): The default SQL database storage using Rails ActiveRecord
- **Redcord Redis Backend** (`:redcord_redis`): Redis-based storage using the Redcord gem with a standard Redis server
- **Redcord Redis Emulator Backend** (`:redcord_redis_emulator`): Redis-compatible storage using Redcord with redis-emulator backed by Rails Solid Cache
- **Redis Emulator**: A Redis-compatible interface backed by Rails Solid Cache

## Configuration

- **Configuration File**: A Ruby file (config/initializers/active_data_flow.rb) where users configure the gem
- **Storage Backend Loader**: Component that loads the appropriate model implementations based on configuration

## Error Classes

- **ConfigurationError**: Raised when storage backend configuration is invalid
- **ConnectionError**: Raised when Redis connection fails
- **DependencyError**: Raised when required gems are not installed
