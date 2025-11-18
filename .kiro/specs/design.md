# Design Document

## Overview

This design implements the ActiveDataflow gem suite for Rails applications. The system provides a modular stream processing framework with pluggable sources, sinks, and runtimes.

See: `.kiro/specs/requirements.md` for detailed requirements
See: `.kiro/glossary.md` for term definitions

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Rails Application                     │
├─────────────────────────────────────────────────────────┤
│                  ActiveDataflow Engine                   │
│  ┌────────────┐  ┌────────────┐  ┌──────────────────┐  │
│  │Controllers │  │   Models   │  │  Heartbeat       │  │
│  │            │  │            │  │  Endpoint        │  │
│  └────────────┘  └────────────┘  └──────────────────┘  │
├─────────────────────────────────────────────────────────┤
│                   Core Abstractions                      │
│  ┌────────────┐  ┌────────────┐  ┌──────────────────┐  │
│  │  DataFlow  │  │ Connector  │  │    Runtime       │  │
│  │            │  │ Source/Sink│  │                  │  │
│  └────────────┘  └────────────┘  └──────────────────┘  │
├─────────────────────────────────────────────────────────┤
│              Concrete Implementations                    │
│  ┌────────────────────────────────────────────────────┐ │
│  │  Subgems (in-repo, part of active_data_flow)      │ │
│  │  - connector/source/active_record                  │ │
│  │  - connector/sink/active_record                    │ │
│  │  - runtime/heartbeat                               │ │
│  └────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

## Components and Interfaces

### 1. Core Abstractions (lib/)

**Purpose**: Define placeholder modules for the monorepo structure

**Structure**:
- `lib/connector/` - Connector placeholders
  - `lib/connector/source/` - Source placeholders
  - `lib/connector/sink/` - Sink placeholders
- `lib/message/` - Message type placeholders
- `lib/runtime/` - Runtime placeholders

See: Requirements 1, 4, 8

### 2. Message Types

**Purpose**: Standardize data containers passed between components

**Classes**:
- `ActiveDataflow::Message::Typed` - Messages with schema validation
- `ActiveDataflow::Message::Untyped` - Flexible messages

See: Requirement 2

### 3. Connector Abstractions

**Purpose**: Define interfaces for reading/writing external systems

**Base Classes**:
- `ActiveDataflow::Connector::Source` - Base source with `each` method
- `ActiveDataflow::Connector::Sink` - Base sink with `write` method

**Implementations**:
- `ActiveDataflow::Connector::Source::ActiveRecord` - Database reading
- `ActiveDataflow::Connector::Sink::ActiveRecord` - Database writing

See: Requirements 1, 3

### 4. Runtime Abstractions

**Purpose**: Define execution environment interfaces

**Base Classes**:
- `ActiveDataflow::Runtime` - Base runtime class
- `ActiveDataflow::Runtime::Runner` - Base runner class

**Implementations**:
- `ActiveDataflow::Runtime::Heartbeat` - Periodic REST-triggered execution
- `ActiveDataflow::Runtime::Heartbeat::Runner` - Heartbeat execution logic

See: Requirements 4, 5

### 5. DataFlow Orchestration

**Purpose**: Coordinate source-transform-sink pipelines

**Base Class**:
- `ActiveDataflow::DataFlow` - Orchestration base class

**Responsibilities**:
- Configure sources and sinks
- Execute read-transform-write loops
- Handle errors and logging

See: Requirement 7

### 6. Rails Engine Integration

**Purpose**: Provide Rails-native management interface

**Components**:
- Controllers for DataFlow CRUD operations
- Models for DataFlow persistence
- Views for monitoring and management
- Routes for heartbeat endpoints

See: Requirement 6
See: `.kiro/steering/rails.rb` for detailed Rails engine implementation

## Data Models

### Database Schema

See individual subgem design documents for detailed schemas:
- `hide/subgems/runtime/heartbeat/.kiro/specs/design.md` - Heartbeat runtime models
- `hide/subgems/connector/source/active_record/.kiro/specs/design.md` - ActiveRecord source models
- `hide/subgems/connector/sink/active_record/.kiro/specs/design.md` - ActiveRecord sink models

See: `.kiro/steering/rails.rb` for Rails engine models (DataFlow, DataFlowRun)

## Module Organization

### Monorepo Structure

The active_data_flow repository contains both core abstractions and concrete implementations:

```
active_data_flow/
├── lib/                    # Core abstractions (placeholder modules)
├── app/                    # Rails engine (controllers, models, services)
└── subgems/                # Concrete implementations (part of this repo)
    ├── connector/
    │   ├── source/
    │   │   └── active_record/    # Full gem with gemspec
    │   └── sink/
    │       └── active_record/    # Full gem with gemspec
    └── runtime/
        └── heartbeat/            # Full gem with gemspec
```

Each subgem is a complete gem with its own gemspec, tests, and documentation, but developed and versioned within the active_data_flow repository.

See: `.kiro/steering/structure.md` for detailed structure
See: Requirement 8

## Error Handling

### Strategy

1. **Connector Errors**: Gracefully handle database/external system failures
2. **Runtime Errors**: Log errors with backtraces, update status
3. **Validation Errors**: Prevent invalid configurations
4. **Transformation Errors**: Allow DataFlows to implement custom error handling

See individual component design documents for specific error handling strategies.

## Testing Strategy

See: `.kiro/steering/tech.md` for testing framework (RSpec)

### Test Organization

- **Unit Tests**: Test individual classes and methods
- **Integration Tests**: Test component interactions
- **System Tests**: Test end-to-end DataFlow execution

See individual subgem design documents for specific test strategies.

## Implementation Notes

### Design Principles

1. **DRY**: Reference existing documents rather than duplicating content
2. **Modularity**: Separate concerns into subgems and submodules
3. **Rails Conventions**: Follow Rails patterns for engine integration
4. **Extensibility**: Allow custom sources, sinks, and runtimes

### Technology Stack

See: `.kiro/steering/tech.md` for complete technology stack

### Next Steps

See: `.kiro/specs/tasks.md` (to be created) for implementation tasks
