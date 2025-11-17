# Project Structure

## Repository Organization

This is a monorepo containing specifications and submodules for the ActiveDataFlow gem suite.
Active Dataflow gem defines common interfaces required for interoperability with plugin connectors and runtimes.

It also implements a RAILS ENGINE to cleanly handle DataFlow-Specific models,  controllers, and views in the context of complex existing RAILS applications.
```
/
├── .kiro/                   # Kiro configuration and specs
├── docs/                    # Documentation and design documents
├── examples/                # Example applications (as submodules)
├── subgems/                 # Gems implementing Components managed in Active Dataflow repo
├── submodules/              # Gems implementing Components managed in other repos
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


## SubGems
These gems are stored in the same git repo as the active_data_flow. This provides 'turnkey' installation and use for simple use-cases.

Example of SubGem active_data_flow-connector-source-active_record:

```
active_data_flow/
└── subgems/
    └── connector/
        └── source/
            └── active_record/    # connector source active_record implementation GEM
```

## SubModule

Each gem is developed as a separate git submodule under `/submodules`:

- `examples/` - Example applications demonstrating usage

## Code Organization Patterns

### Module Naming

- Core module: `ActiveDataflow`
- Connectors: `ActiveDataflow::Connector::Source::*` and `ActiveDataflow::Connector::Sink::*`
- Runtimes: `ActiveDataflow::Runtime::*`

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

1. Core gem establishes interfaces
2. Runtime gems implement execution environments
3. Connector gems implement data sources/sinks
4. Example apps demonstrate integration
5. Each component is independently versioned as a gem
