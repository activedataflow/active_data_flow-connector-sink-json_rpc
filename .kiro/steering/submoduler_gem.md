# Submoduler Gem Guide

## Overview

The `submoduler` gem is the base tool for managing git submodules and monorepo structures. It provides the foundation for both `submoduler_parent` and `submoduler_child` gems used in the active_data_flow project.

**Submoduler Ecosystem**:
- **`submoduler`** - Base gem with core functionality
- **`submoduler_parent`** - Used by parent repositories (active_data_flow)
- **`submoduler_child`** - Used by child components (subgems)

## Vendored Location

The base submoduler gem is vendored at:
```
vendor/submoduler/
├── .git/                       # Git repository
├── .gitmodules                 # Git submodules configuration
├── .kiro/                      # Kiro specifications
├── .submoduler.ini             # Submoduler configuration
├── bin/                        # Executables
├── lib/                        # Library code
├── examples/                   # Example projects
├── submodules/                 # Submodules (parent and child gems)
│   └── core/
│       ├── submoduler_child/
│       └── submoduler_parent/
└── test/                       # Tests
```

## Purpose

The submoduler gem provides:

1. **Monorepo Management**: Tools for managing multiple gems in one repository
2. **Submodule Coordination**: Git submodule management and validation
3. **Parent-Child Relationships**: Enable communication between parent and child components
4. **Build Tools**: Commands for building, testing, and validating monorepo structure
5. **Configuration Management**: `.submoduler.ini` file handling

## Configuration

### .submoduler.ini Format

The submoduler gem uses `.submoduler.ini` files for configuration:

```ini
[default]

[submodule "core/submoduler_child"]
    path = submodules/core/submoduler_child
    seperate_repo = false

[submodule "core/submoduler_parent"]
    path = submodules/core/submoduler_parent
    seperate_repo = false
```

**Key Fields**:
- `path` - Location of the submodule
- `seperate_repo` - Whether it's a separate git repository (true) or in-repo (false)

## Relationship to Active Data Flow

### Dependency Chain

```
active_data_flow
├── Uses: submoduler_parent (vendored in vendor/submoduler_parent)
│   └── Depends on: submoduler (base gem)
│
└── subgems/
    ├── active_data_flow-connector-source-active_record
    │   ├── Uses: submoduler_child (vendored in vendor/submoduler_child)
    │   │   └── Depends on: submoduler (base gem)
    │   └── References parent via .submoduler.ini
    │
    ├── active_data_flow-connector-sink-active_record
    │   └── Uses: submoduler_child
    │
    └── active_data_flow-runtime-heartbeat
        └── Uses: submoduler_child
```

### How It Works

1. **Base Functionality**: `submoduler` provides core monorepo tools
2. **Parent Extension**: `submoduler_parent` extends base for parent repositories
3. **Child Extension**: `submoduler_child` extends base for child components
4. **Coordination**: Both parent and child gems use submoduler's configuration system

## Vendored Gems Structure

All three submoduler gems are vendored:

```
vendor/
├── submoduler/                 # Base gem
│   ├── submodules/
│   │   └── core/
│   │       ├── submoduler_child/    # Child gem source
│   │       └── submoduler_parent/   # Parent gem source
│   └── ...
│
├── submoduler_parent/          # Parent gem (separate clone)
│   ├── .git/
│   ├── lib/
│   └── submoduler_parent.gemspec
│
└── submoduler_child/           # Child gem (separate clone)
    ├── .git/
    ├── lib/
    └── submoduler_child.gemspec
```

**Note**: The parent and child gems exist both as submodules within `vendor/submoduler/` and as separate clones in `vendor/submoduler_parent/` and `vendor/submoduler_child/`.

## Core Concepts

### Monorepo Structure

Submoduler enables:
- **Single Repository**: Multiple gems in one repo
- **Independent Versioning**: Each gem has its own version
- **Shared Configuration**: Common settings via .submoduler.ini
- **Coordinated Builds**: Build all gems together or individually

### Parent-Child Pattern

- **Parent** (active_data_flow):
  - Manages overall repository
  - References child components
  - Provides shared configuration
  - Uses `submoduler_parent` gem

- **Children** (subgems):
  - Implement specific functionality
  - Reference parent for shared resources
  - Independent but coordinated
  - Use `submoduler_child` gem

### Configuration Hierarchy

```
active_data_flow/
├── .submoduler.ini (if exists)     # Parent configuration
└── subgems/
    └── component/
        └── .submoduler.ini         # Child configuration
            └── References parent path
```

## Commands and Tools

While the base `submoduler` gem provides core functionality, most commands are accessed through the parent or child gems:

### Via Submoduler Parent

```bash
# In parent repository (active_data_flow)
bundle exec submoduler_parent validate
bundle exec submoduler_parent report
```

### Via Submoduler Child

```bash
# In child component (subgem)
bundle exec submoduler_child init
bundle exec submoduler_child status
bundle exec submoduler_child build
```

## Development Workflow

### Using Vendored Submoduler

The vendored submoduler gems are already available. No installation needed beyond bundle install.

### Updating Vendored Copies

```bash
# Update base submoduler
cd vendor/submoduler
git pull origin main
cd ../..

# Update parent gem
cd vendor/submoduler_parent
git pull origin main
cd ../..

# Update child gem
cd vendor/submoduler_child
git pull origin main
cd ../..

# Commit updates
git add vendor/
git commit -m "Update vendored submoduler gems"
```

### Local Development

To use vendored copies during development, modify Gemfiles:

**Parent Gemfile** (active_data_flow):
```ruby
# gem 'submoduler-core-submoduler_parent', git: '...'
gem 'submoduler-core-submoduler_parent', path: 'vendor/submoduler_parent'
```

**Child Gemfile** (subgem):
```ruby
# gem 'submoduler-core-submoduler_child', git: '...'
gem 'submoduler-core-submoduler_child', path: '../../../vendor/submoduler_child'
```

## Integration Patterns

### Subgem Creation with Submoduler

1. **Create directory structure**
2. **Add .submoduler.ini** pointing to parent
3. **Include submoduler_child** in Gemfile
4. **Create symlinks** to parent .kiro/
5. **Initialize** with `bundle exec submoduler_child init`

### Parent-Child Communication

- **Configuration**: Via .submoduler.ini files
- **Documentation**: Via symbolic links to parent .kiro/
- **Dependencies**: Via Gemfile path references
- **Builds**: Coordinated through submoduler tools

## Best Practices

### Configuration

- **Use .submoduler.ini**: For all parent-child relationships
- **Set correct paths**: Relative paths to parent
- **Document structure**: Keep configuration clear

### Versioning

- **Independent versions**: Each gem versions separately
- **Coordinate releases**: Plan releases across parent and children
- **Update together**: Keep vendored copies in sync

### Development

- **Test locally**: Use vendored copies for offline work
- **Validate structure**: Use submoduler validation tools
- **Keep updated**: Regularly update vendored gems

## Troubleshooting

### Submoduler Not Found

```bash
# Check vendored copies exist
ls -la vendor/submoduler*

# Verify Gemfile references
grep submoduler Gemfile
```

### Configuration Issues

```bash
# Validate .submoduler.ini
cat .submoduler.ini

# Check parent path
grep "path.*parent" .submoduler.ini
```

### Version Conflicts

```bash
# Check vendored versions
cat vendor/submoduler_parent/submoduler_parent.gemspec | grep version
cat vendor/submoduler_child/submoduler_child.gemspec | grep version

# Update if needed
cd vendor/submoduler_parent && git pull
cd vendor/submoduler_child && git pull
```

### Build Issues

```bash
# Ensure all gems are installed
bundle install

# Check for missing dependencies
bundle check
```

## Architecture

### Gem Hierarchy

```
submoduler (base)
├── Core functionality
├── Configuration management
├── Monorepo tools
│
├── submoduler_parent (extends base)
│   ├── Parent-specific commands
│   ├── Child management
│   └── Repository validation
│
└── submoduler_child (extends base)
    ├── Child-specific commands
    ├── Parent reference
    └── Build tools
```

### File Organization

```
active_data_flow/
├── Gemfile                     # References submoduler_parent
├── vendor/
│   ├── submoduler/             # Base gem
│   ├── submoduler_parent/      # Parent gem
│   └── submoduler_child/       # Child gem
└── subgems/
    └── component/
        ├── Gemfile             # References submoduler_child
        └── .submoduler.ini     # Points to parent
```

## Related Documentation

- **Submoduler Parent**: `.kiro/steering/submodules_parent.md` - Parent gem guide
- **Submoduler Child**: `.kiro/steering/submoduler_child.md` - Child gem guide
- **Subgems Guide**: `.kiro/steering/subgems.md` - Subgem development
- **Gemfile Guidelines**: `.kiro/steering/gemfiles.md` - Gemfile patterns
- **Project Structure**: `.kiro/steering/structure.md` - Repository organization

## Version Information

Current vendored versions:
- **submoduler**: Check `vendor/submoduler/`
- **submoduler_parent**: 0.2.0 (in `vendor/submoduler_parent/`)
- **submoduler_child**: 0.2.0 (in `vendor/submoduler_child/`)

## External Resources

- Submoduler Repository: https://github.com/magenticmarketactualskill/submoduler-core-submoduler_child
- Git Submodules Documentation: https://git-scm.com/book/en/v2/Git-Tools-Submodules
