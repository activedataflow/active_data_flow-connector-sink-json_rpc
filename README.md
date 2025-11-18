# ActiveDataFlow - Modular Ruby Gem Suite

A modular stream processing framework for Ruby inspired by Apache Flink. ActiveDataFlow provides a plugin-based architecture where the core gem defines abstract interfaces, and separate gems provide concrete implementations for different runtimes and connectors.

## Documentation Structure

This project follows a structured documentation approach using the `.kiro/` directory:

### Core Documentation

- **[Requirements](.kiro/specs/requirements.md)** - Detailed functional requirements with EARS-formatted acceptance criteria
- **[Design](.kiro/specs/design.md)** - System architecture and component design
- **[Tasks](.kiro/specs/tasks.md)** - Implementation task list with progress tracking
- **[Glossary](.kiro/glossary.md)** - Domain terminology and definitions

### Steering Guidelines

The `.kiro/steering/` directory contains development guidelines:

- **[Product Overview](.kiro/steering/product.md)** - Product vision and key components
- **[Project Structure](.kiro/steering/structure.md)** - Repository organization and conventions
- **[Technology Stack](.kiro/steering/tech.md)** - Languages, frameworks, and tools
- **[Gem Design](.kiro/steering/design_gem.md)** - Gem structure and naming conventions
- **[Rails Engine](.kiro/steering/rails.rb)** - Rails engine implementation details
- **[DRY Principle](.kiro/steering/dry.md)** - Documentation best practices

## Architecture Overview

See: [Design Document](.kiro/specs/design.md) for detailed architecture

ActiveDataFlow follows a plugin-based architecture:

```
active_data_flow (core)
├── Runtime Implementations
│   ├── rails_heartbeat_app (Rails engine with periodic execution)
│   ├── rails_heartbeat_job (ActiveJob-based execution)
│   ├── aws_lambda (Serverless execution)
│   └── flink (Distributed processing)
├── Connector Implementations
│   ├── active_record (Database tables)
│   ├── rafka (Kafka-compatible Redis streams)
│   ├── cache (Rails cache)
│   ├── file (CSV, JSON files)
│   └── iceberg (Apache Iceberg tables)
└── Framework Extensions
    └── source_support (Split-based sources)
```

## Message Types

See: [Requirements](.kiro/specs/requirements.md) - Requirement 2

All DataFlows work with `ActiveDataflow::Message` instances:

- **`ActiveDataflow::Message::Untyped`** - Flexible data handling without schema validation
- **`ActiveDataflow::Message::Typed`** - Schema-validated messages with type checking

## Core Components

See: [Design Document](.kiro/specs/design.md) - Components and Interfaces

### Base Classes

- **`ActiveDataflow::Connector::Source::Base`** - Abstract source with `each` method
- **`ActiveDataflow::Connector::Sink::Base`** - Abstract sink with `write` method
- **`ActiveDataflow::Runtime::Base`** - Abstract runtime execution environment
- **`ActiveDataflow::Runtime::Runner`** - Base runner for DataFlow execution
- **`ActiveDataflow::DataFlow`** - Orchestration base class

### Rails Engine Integration

See: [Rails Engine Documentation](.kiro/steering/rails.rb)

The Rails engine provides:
- **Models**: `DataFlow`, `DataFlowRun` for configuration and execution tracking
- **Controllers**: `DataFlowsController` with heartbeat endpoint
- **Services**: `FlowExecutor` for orchestrating flow execution
- **Security**: Token authentication and IP whitelisting

## Repository Structure

See: [Project Structure](.kiro/steering/structure.md)

This is a monorepo containing the core gem and subgems (all part of the active_data_flow repository):

```
active_data_flow/
├── .kiro/                   # Specifications and steering guidelines
│   ├── specs/               # Requirements, design, tasks
│   ├── steering/            # Development guidelines
│   └── glossary.md          # Domain terminology
├── app/                     # Rails engine components
│   ├── controllers/         # DataFlow management controllers
│   ├── models/              # DataFlow and DataFlowRun models
│   └── services/            # Flow execution services
├── lib/                     # Core abstractions (placeholder modules)
│   ├── connector/           # Source and Sink base classes
│   ├── message/             # Message type implementations
│   ├── runtime/             # Runtime base classes
│   └── active_data_flow.rb  # Main gem entry point
├── subgems/                 # Concrete implementations (part of this repo)
│   ├── connector/
│   │   ├── source/
│   │   │   └── active_record/    # Complete gem with gemspec
│   │   └── sink/
│   │       └── active_record/    # Complete gem with gemspec
│   └── runtime/
│       └── heartbeat/            # Complete gem with gemspec
├── examples/                # Example applications
└── test/                    # Test suite
```

**Note:** Subgems are not git submodules - they are part of the active_data_flow repository but can be published as independent gems.

## Development Workflow

See: [Tasks Document](.kiro/specs/tasks.md) for implementation progress

1. **Core Development**: Establish abstract interfaces in `lib/`
2. **Runtime Development**: Implement execution environments in `subgems/runtime/`
3. **Connector Development**: Implement sources/sinks in `subgems/connector/`
4. **Integration Testing**: Test combinations of runtimes and connectors

## Example Usage

```ruby
# Gemfile
gem 'active_data_flow'
gem 'active_data_flow-rails_heartbeat_app'
gem 'active_data_flow-connector-source-active_record'
gem 'active_data_flow-connector-sink-active_record'

# app/data_flows/product_sync_flow.rb
class ProductSyncFlow < ActiveDataflow::DataFlow
  def initialize(config)
    super
    @source = ActiveDataflow::Connector::Source::ActiveRecord.new(
      model: config[:source_model]
    )
    @sink = ActiveDataflow::Connector::Sink::ActiveRecord.new(
      model: config[:sink_model]
    )
  end

  def run
    @source.each do |record|
      transformed = transform(record)
      @sink.write(transformed)
    end
  end

  private

  def transform(record)
    # Custom transformation logic
    record.merge(processed_at: Time.current)
  end
end
```

## Getting Started

1. **Read the Requirements**: Start with [requirements.md](.kiro/specs/requirements.md)
2. **Understand the Design**: Review [design.md](.kiro/specs/design.md)
3. **Check Implementation Status**: See [tasks.md](.kiro/specs/tasks.md)
4. **Follow Guidelines**: Reference steering files in `.kiro/steering/`

## Testing

See: [Technology Stack](.kiro/steering/tech.md) for testing framework details

```bash
# Run all tests
ruby -Ilib:test -e 'Dir.glob("test/**/*test*.rb").each { |f| require_relative f }'

# Run specific test file
ruby -Ilib:test test/path/to/test_file.rb

# Run RSpec tests (in subgems/examples)
bundle exec rspec
```

## Dependencies

See: [Requirements](.kiro/specs/requirements.md) - Requirement 8

| Gem | Depends On |
|-----|------------|
| `active_data_flow` | (none) |
| `active_data_flow-source_support` | core |
| `active_data_flow-runtime-heartbeat` | core, rails |
| `active_data_flow-connector-source-active_record` | core, activerecord |
| `active_data_flow-connector-sink-active_record` | core, activerecord |

## Contributing

1. Review [DRY principles](.kiro/steering/dry.md) - Reference existing docs, don't duplicate
2. Follow [gem design guidelines](.kiro/steering/design_gem.md)
3. Update relevant `.kiro/` documentation when making changes
4. Ensure tests pass before submitting changes

## License

[Add license information]

## Additional Resources

- **Requirements**: [.kiro/specs/requirements.md](.kiro/specs/requirements.md)
- **Design**: [.kiro/specs/design.md](.kiro/specs/design.md)
- **Implementation Tasks**: [.kiro/specs/tasks.md](.kiro/specs/tasks.md)
- **Glossary**: [.kiro/glossary.md](.kiro/glossary.md)
- **Product Overview**: [.kiro/steering/product.md](.kiro/steering/product.md)
- **Rails Engine**: [.kiro/steering/rails.rb](.kiro/steering/rails.rb)
