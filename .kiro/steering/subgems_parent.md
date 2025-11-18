# Subgems Guide

## Overview

Subgems are complete Ruby gems developed within the active_data_flow repository. They package specific functionality (connectors, runtimes) as independent gems while being managed in the same repository as the core gem.

**Key Distinction**: Subgems are NOT git submodules - they are part of the active_data_flow repository.

## Why Subgems?

- **Modular Development**: Each component can be developed independently
- **Independent Versioning**: Subgems can have their own version numbers
- **Selective Installation**: Users install only the subgems they need
- **Shared Repository**: All code in one place for easier coordination
- **Turnkey Installation**: Common use-cases work out of the box

## Subgem Structure

Each subgem follows this standard structure:

```
subgems/active_data_flow-{component}-{type}-{name}/
├── lib/
│   ├── active_data_flow/
│   │   └── {component}/
│   │       └── {type}/
│   │           ├── {name}.rb           # Main implementation
│   │           └── {name}/
│   │               └── version.rb      # Version constant
│   └── active_data_flow-{component}-{type}-{name}.rb  # Entry point
├── spec/
│   ├── spec_helper.rb
│   └── {name}_spec.rb
├── .kiro/
│   ├── specs/
│   │   ├── requirements.md             # Subgem-specific requirements
│   │   ├── design.md                   # Implementation design
│   │   ├── tasks.md                    # Implementation tasks
│   │   ├── parent_requirements.md      # Symlink to parent
│   │   └── parent_design.md            # Symlink to parent
│   ├── steering/                       # All symlinks to parent
│   │   ├── glossary.md
│   │   ├── product.md
│   │   ├── structure.md
│   │   ├── tech.md
│   │   ├── design_gem.md
│   │   ├── dry.md
│   │   ├── test_driven_design.md
│   │   └── gemfiles.md
│   ├── settings/
│   └── README.md
├── active_data_flow-{component}-{type}-{name}.gemspec
├── Gemfile
├── Rakefile
├── README.md
├── CHANGELOG.md
├── .gitignore
└── .rspec
```

## Naming Conventions

### Gem Names
- Pattern: `active_data_flow-{component}-{type}-{name}`
- Examples:
  - `active_data_flow-connector-source-active_record`
  - `active_data_flow-connector-sink-active_record`
  - `active_data_flow-runtime-heartbeat`

### Module Names
- Pattern: `ActiveDataflow::{Component}::{Type}::{Name}`
- Examples:
  - `ActiveDataflow::Connector::Source::ActiveRecord`
  - `ActiveDataflow::Connector::Sink::ActiveRecord`
  - `ActiveDataflow::Runtime::Heartbeat`

### File Paths
Match module structure:
- `lib/active_data_flow/connector/source/active_record.rb`
- `lib/active_data_flow/connector/sink/active_record.rb`
- `lib/active_data_flow/runtime/heartbeat.rb`

## Current Subgems

### Connectors

**Source Connectors** (read data from external systems):
- `active_data_flow-connector-source-active_record` - Read from database tables

**Sink Connectors** (write data to external systems):
- `active_data_flow-connector-sink-active_record` - Write to database tables

### Runtimes

**Execution Environments**:
- `active_data_flow-runtime-heartbeat` - Rails engine with periodic HTTP-triggered execution

## Creating a New Subgem

### 1. Directory Structure

```bash
mkdir -p subgems/active_data_flow-{component}-{type}-{name}/{lib/active_data_flow/{component}/{type},spec,.kiro/{specs,steering,settings}}
```

### 2. Core Files

Create these essential files:
- `{name}.gemspec` - Gem specification
- `Gemfile` - Development dependencies
- `Rakefile` - Build tasks
- `README.md` - Usage documentation
- `CHANGELOG.md` - Version history
- `.gitignore` - Git exclusions
- `.rspec` - RSpec configuration

### 3. Implementation Files

- `lib/active_data_flow/{component}/{type}/{name}.rb` - Main implementation
- `lib/active_data_flow/{component}/{type}/{name}/version.rb` - Version constant
- `lib/active_data_flow-{component}-{type}-{name}.rb` - Entry point

### 4. .kiro Structure

**Create symlinks to parent steering**:
```bash
cd subgems/active_data_flow-{component}-{type}-{name}/.kiro/steering
ln -sf ../../../../.kiro/glossary.md glossary.md
ln -sf ../../../../.kiro/steering/product.md product.md
ln -sf ../../../../.kiro/steering/structure.md structure.md
ln -sf ../../../../.kiro/steering/tech.md tech.md
ln -sf ../../../../.kiro/steering/design_gem.md design_gem.md
ln -sf ../../../../.kiro/steering/dry.md dry.md
ln -sf ../../../../.kiro/steering/test_driven_design.md test_driven_design.md
ln -sf ../../../../.kiro/steering/gemfiles.md gemfiles.md
```

**Create symlinks to parent specs**:
```bash
cd subgems/active_data_flow-{component}-{type}-{name}/.kiro/specs
ln -sf ../../../../.kiro/specs/requirements.md parent_requirements.md
ln -sf ../../../../.kiro/specs/design.md parent_design.md
```

**Create subgem-specific docs**:
- `.kiro/specs/requirements.md` - Subgem requirements
- `.kiro/specs/design.md` - Implementation design
- `.kiro/specs/tasks.md` - Implementation tasks
- `.kiro/README.md` - .kiro structure guide

### 5. Gemfile Template

See: `.kiro/steering/gemfiles.md` for complete Gemfile guidelines

```ruby
# frozen_string_literal: true

source 'https://rubygems.org'

git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# Submoduler child gem
gem 'submoduler-core-submoduler_child', git: 'https://github.com/magenticmarketactualskill/submoduler-core-submoduler_child.git'

gemspec
```

### 6. Gemspec Template

```ruby
# frozen_string_literal: true

require_relative "lib/active_data_flow/{component}/{type}/{name}/version"

Gem::Specification.new do |spec|
  spec.name          = "active_data_flow-{component}-{type}-{name}"
  spec.version       = ActiveDataflow::{Component}::{Type}::{Name}::VERSION
  spec.authors       = ["ActiveDataflow Team"]
  spec.email         = ["team@example.com"]

  spec.summary       = "Brief description"
  spec.description   = "Detailed description"
  spec.homepage      = "https://github.com/yourusername/active_data_flow"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 2.7.0"

  spec.files = Dir["lib/**/*", "README.md", "LICENSE.txt", "CHANGELOG.md"]
  spec.require_paths = ["lib"]

  # Core dependency
  spec.add_dependency "active_data_flow", "~> 0.1"
  
  # Component-specific dependencies
  # spec.add_dependency "activerecord", ">= 6.0"

  # Development dependencies
  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
```

## Development Workflow

### Local Development

1. **Work in subgem directory**:
   ```bash
   cd subgems/active_data_flow-connector-source-active_record
   bundle install
   bundle exec rspec
   ```

2. **Test from parent**:
   Add path reference to parent Gemfile:
   ```ruby
   gem 'active_data_flow-connector-source-active_record', 
       path: 'subgems/active_data_flow-connector-source-active_record'
   ```

3. **Run parent tests**:
   ```bash
   cd ../..  # Back to active_data_flow root
   bundle install
   bundle exec rspec
   ```

### Publishing

1. **Update version** in `lib/active_data_flow/{component}/{type}/{name}/version.rb`
2. **Update CHANGELOG.md**
3. **Build gem**: `gem build active_data_flow-{component}-{type}-{name}.gemspec`
4. **Publish**: `gem push active_data_flow-{component}-{type}-{name}-{version}.gem`

## Best Practices

### Code Organization

- **Single Responsibility**: Each subgem does one thing well
- **Minimal Dependencies**: Only depend on what's necessary
- **Clear Interfaces**: Follow parent abstract base classes
- **Comprehensive Tests**: Test all public interfaces

### Documentation

- **README**: Clear usage examples
- **CHANGELOG**: Document all changes
- **Requirements**: EARS-formatted acceptance criteria
- **Design**: Architecture and implementation details
- **Tasks**: Implementation checklist

### Version Management

- **Semantic Versioning**: MAJOR.MINOR.PATCH
- **Independent Versions**: Each subgem versions independently
- **Compatibility**: Document compatibility with core gem versions

## Troubleshooting

### Bundle Issues

If `bundle install` fails in a subgem:
1. Check Gemfile has correct submoduler_child reference
2. Verify gemspec dependencies are correct
3. Try `bundle update` to refresh dependencies

### Symlink Issues

If symlinks are broken:
1. Verify path depth (should be `../../../../` for subgems)
2. Check parent files exist
3. Recreate symlinks with correct paths

### Import Issues

If Ruby can't find modules:
1. Check file paths match module structure
2. Verify entry point requires main implementation
3. Check gemspec `require_paths` includes "lib"

## Related Documentation

- **Gem Design**: `.kiro/steering/design_gem.md`
- **Gemfile Guidelines**: `.kiro/steering/gemfiles.md`
- **Project Structure**: `.kiro/steering/structure.md`
- **Technology Stack**: `.kiro/steering/tech.md`
