# Project Structure

## Repository Organization

This is a monorepo containing the ActiveDataFlow gem suite with integrated submodules.
Active Dataflow gem defines common interfaces required for interoperability with plugin connectors and runtimes.

It also implements a RAILS ENGINE to cleanly handle DataFlow-Specific models, controllers, and views in the context of complex existing RAILS applications.
```
/
├── .kiro/                   # Kiro configuration and specs
├── docs/                    # Documentation and design documents
├── examples/                # Example applications (as submodules)
├── submodules/              # Component gems managed as git submodules
├── lib/                     # Placeholder module definitions
│   ├── connector/           # Connector placeholder modules
│   │   ├── sink/
│   │   └── source/
│   ├── message/             # Message type placeholders
│   └── runtime/             # Runtime placeholder modules
├── test/                    # RSpec tests
├── bin/                     # Executable scripts
└── vendor/                  # Vendored dependencies
```


## Submodules (Component Gems)

All component implementations are managed as git submodules in the `submodules/` directory. These provide 'turnkey' installation and use for common use-cases. Each submodule is a complete gem with its own gemspec, managed in a separate git repository.

Example of submodule active_data_flow-connector-source-active_record:

```
active_data_flow/
└── submodules/
    └── active_data_flow-connector-source-active_record/    # connector source active_record implementation GEM
        ├── lib/
        ├── spec/
        ├── .kiro/
        ├── active_data_flow-connector-source-active_record.gemspec
        └── README.md
```

**Key Submodules:**
- `submodules/active_data_flow-connector-source-active_record/` - ActiveRecord source connector
- `submodules/active_data_flow-connector-sink-active_record/` - ActiveRecord sink connector
- `submodules/active_data_flow-runtime-heartbeat/` - Rails heartbeat runtime
- `submodules/examples/rails8-demo/` - Example Rails 8 application

## Code Organization Patterns

### Module Naming

- Core module: `ActiveDataFlow`
- Connectors: `ActiveDataFlow::Connector::Source::*` and `ActiveDataFlow::Connector::Sink::*`
- Runtimes: `ActiveDataFlow::Runtime::*`

### Gem Naming

- Core gem: `active_data_flow`
- Connectors: `active_data_flow-connector-*`
- Sources: `active_data_flow-connector-source-*`
- Sinks: `active_data_flow-connector-sink-*`
- Runtimes: `active_data_flow-runtime-*`

## Key Directories

- **docs/**: Contains requirements, design documents, and architecture specs
- **lib/**: Placeholder modules for the monorepo structure
- **test/**: RSpec-based tests
- **bin/**: Command-line tools
- **.kiro/specs/**: Detailed requirements and specifications for each component

## Development Workflow

1. **Core gem** (`lib/`) establishes abstract interfaces
2. **Submodules** (`submodules/`) provide concrete implementations:
   - Runtime gems implement execution environments
   - Connector gems implement data sources/sinks
3. **Rails engine** (`app/`) provides management interface
4. **Example apps** demonstrate integration
5. Each submodule can be independently versioned and published as a gem
