# Technology Stack

## Language & Framework

- **Ruby**: Primary language (2.7+)
- **Rails**: Used for ActiveRecord integration and heartbeat runtime


## Build System

- **Bundler**: Dependency management via Gemfile
- **RubyGems**: Gem packaging and distribution
- **Submoduler**: Custom tool for managing git submodules in monorepo structure

## Testing

- **RSpec**: Testing framework and used in example applications

## Key Dependencies

- ActiveRecord (for database connectors)

## Common Commands

```bash
# Install dependencies
bundle install

# Run tests
ruby -Ilib:test -e 'Dir.glob("test/**/*test*.rb").each { |f| require_relative f }'

# Run specific test file
ruby -Ilib:test test/path/to/test_file.rb

# Validate submodule configuration
ruby bin/submoduler.rb report

# Run RSpec tests (in example apps)
bundle exec rspec
```

## Project Management

The project uses a monorepo structure with either a subgem or a git submodules for each gem. The `.submoduler.ini` file defines submodule paths and URLs. The custom `submoduler` tool validates submodule configuration.
