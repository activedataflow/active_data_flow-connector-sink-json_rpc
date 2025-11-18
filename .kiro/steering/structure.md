# Project Structure

## Repository Organization

This is a monorepo containing the ActiveDataFlow gem suite with integrated subgems.
Active Dataflow gem defines common interfaces required for interoperability with plugin connectors and runtimes.

It also implements a RAILS ENGINE to cleanly handle DataFlow-Specific models, controllers, and views in the context of complex existing RAILS applications.
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


## SubGems (In-Repo Components)

Subgems are part of the active_data_flow repository, stored in the `subgems/` directory. These provide 'turnkey' installation and use for common use-cases. Each subgem is a complete gem with its own gemspec, but managed within the same repository.

Example of SubGem active_data_flow-connector-source-active_record:

```
active_data_flow/
└── subgems/
    └── connector/
        └── source/
            └── active_record/    # connector source active_record implementation GEM
                ├── lib/
                ├── spec/
                ├── .kiro/
                ├── active_data_flow-connector-source-active_record.gemspec
                └── README.md
```

**Key SubGems:**
- `subgems/connector/source/active_record/` - ActiveRecord source connector
- `subgems/connector/sink/active_record/` - ActiveRecord sink connector
- `subgems/runtime/heartbeat/` - Rails heartbeat runtime

## SubModules (External Repos)

Some components are developed as separate git submodules under `/submodules/` when they need independent repository management:

- `submodules/` - Components managed in separate repositories
- `examples/` - Example applications demonstrating usage (may be submodules)

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

1. **Core gem** (`lib/`) establishes abstract interfaces
2. **Subgems** (`subgems/`) provide concrete implementations:
   - Runtime gems implement execution environments
   - Connector gems implement data sources/sinks
3. **Rails engine** (`app/`) provides management interface
4. **Example apps** demonstrate integration
5. Each subgem can be independently versioned and published as a gem
