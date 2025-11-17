# Product Overview

ActiveDataFlow is a modular stream processing framework for Ruby inspired by Apache Flink. It provides a plugin-based architecture where a core gem defines abstract interfaces (Source, Sink, DataFlow) and separate gems provide concrete implementations for different runtimes and connectors.

## Key Components

- **Core**: Abstract interfaces and base classes for sources, sinks, and data flows
- **Runtimes**: Execution environments (Rails Heartbeat, ActiveJob, AWS Lambda, Flink)
- **Connectors**: Data source/sink implementations (Rafka, ActiveRecord, Cache, File, Iceberg)
- **Framework Extensions**: Additional capabilities like split-based source support

## Message Types

All data flows work with `ActiveDataFlow::Message` instances:
- `ActiveDataFlow::Message::Unconstrained` - Generic messages
- `ActiveDataFlow::Message::CloudEvent` - CloudEvents standard
- `ActiveDataFlow::Message::CloudEventLd` - CloudEventsLd format

## Architecture Philosophy

The framework follows a strict separation between abstract interfaces (core) and concrete implementations (runtime/connector gems). This allows applications to mix and match runtimes and connectors based on their needs without tight coupling.
