# Project Structure

## Repository Organization

This is a monorepo containing specifications and submodules for the ActiveDataFlow gem suite.

```
/
├── docs/                    # Documentation and design documents
├── examples/                # Example applications (as submodules)
├── subgems/                 # Gems implementing Components managed in Active Dataflow repo
├── submodules/              # Gems implementing Components managed in other repos
├── lib/                     # Placeholder module definitions
├── test/                    # Integration tests for submoduler tool
├── bin/                     # Executable scripts (submoduler)
└── .kiro/                   # Kiro configuration and specs
```
### File Structure (within Active Dataflow)

Active Dataflow gem defines common interfaces required for interoperability with plugin connectors and runtimes.

It also implements a RAILS ENGINE to cleanly handle DataFlow-Specific models,  controllers, and views in the context of complex existing RAILS applications.    

```
active_data_flow/
├── lib/
│   └── active_data_flow/
│       ├── runtime          # Base runtime class
│           ├── heartbeat    # heartBEat implementation
│       ├── connector        # Base connector class
│           ├── source       # Base source class
│           ├── sink         # Base sink class
├── spec/                    # RSpec tests
├── app/                     # Rails components (for Rails-based gems)
│   ├── models/
│   ├── controllers/
│   └── services/
└── db/migrate/                # Database migrations (if needed)
```


## Submoduler Structure

Submoduler gem provides file structure and automation of SubGem and SubModule components.

## SubGems
These gems are stored in the same git repo as the active_data_flow. This provides 'turnkey' installation and use for simple use-cases.

```
active_data_flow/
├── subgems/
│       ├── connector        # Base connector class
│           ├── source       # Base source class
│               ├── active_record    # connector source active_record implementation GEM
│           ├── sink         # Base sink class
│               ├── active_record    # connector sink active_record implementation GEM

```

## SubModule

Each gem is developed as a separate git submodule under `hide/submodules/`:

- `hide/submodules/core/core/` - Core gem with abstract interfaces
- `hide/submodules/runtime/` - Runtime implementations
- `hide/submodules/connector/` - Connector implementations
- `examples/` - Example applications demonstrating usage

## Code Organization Patterns

### Module Naming

- Core module: `ActiveDataFlow`
- Connectors: `ActiveDataFlow::Source::*` and `ActiveDataFlow::Sink::*`
- Runtimes: Typically integrate with Rails or provide standalone execution


## Key Directories

- **docs/**: Contains requirements, design documents, and architecture specs
- **lib/**: Placeholder modules for the monorepo structure
- **test/**: Minitest-based tests for the submoduler validation tool
- **bin/**: Command-line tools (submoduler.rb)
- **.kiro/specs/**: Detailed requirements and specifications for each component

## Development Workflow

1. Core gem establishes interfaces
2. Runtime gems implement execution environments
3. Connector gems implement data sources/sinks
4. Example apps demonstrate integration
5. Each component is independently versioned as a gem
