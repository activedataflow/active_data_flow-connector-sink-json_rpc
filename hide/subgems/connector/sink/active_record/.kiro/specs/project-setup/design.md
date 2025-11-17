# Design Document

## Overview

This design document outlines the project structure setup for the active_dataflow-connector-active_record gem, following the established patterns from active_data_flow-core-core. The setup ensures consistency across the ActiveDataFlow gem ecosystem, proper dependency management, and a well-organized directory structure for development and testing.

## Architecture

The project follows the standard Ruby gem structure with these key components:

```
active_dataflow-connector-active_record/
├── .kiro/
│   └── specs/
│       └── project-setup/
├── lib/
│   ├── active_data_flow-active_record.rb (main init)
│   └── active_data_flow/
│       ├── active_record/
│       │   └── version.rb
│       ├── source/
│       │   └── active_record.rb
│       └── sink/
│           └── active_record.rb
├── spec/
├── Gemfile
├── active_dataflow-connector-active_record.gemspec
├── LICENSE.txt
├── CHANGELOG.md
└── README.md
```

## Components and Interfaces

### 1. Gemfile

The Gemfile manages dependencies and follows the core-core pattern:

- **Source Configuration**: Uses rubygems.org as the primary gem source
- **Git Source Helper**: Includes git_source configuration for GitHub repos
- **Core Dependency**: References active_data_flow-core-core using path-based dependency pointing to the symlinked core_core directory
- **Development Dependencies**: Groups rspec and other dev tools in development/test group
- **Frozen String Literal**: Uses pragma for performance

**Path Resolution**: The Gemfile will use `path: 'core_core'` to reference the symlinked core-core gem, maintaining consistency with the existing symlink structure.

### 2. .kiro Directory Structure

The .kiro directory provides IDE-specific configuration:

- **Location**: `.kiro/` at project root
- **Specs Subdirectory**: `.kiro/specs/` contains feature specifications
- **Extensibility**: Structure supports multiple feature specs as subdirectories

### 3. Main Init File

The init file at `lib/active_data_flow-active_record.rb` serves as the gem's entry point:

**Load Order**:
1. External dependencies (active_record, active_support)
2. Core framework (active_data_flow)
3. Version file
4. Connector implementations (sink, source)

**Rationale**: This order ensures all dependencies are loaded before the connector code executes, preventing load-time errors.

### 4. Gemspec Configuration

The gemspec follows the core-core pattern with connector-specific adaptations:

**Metadata**:
- Name: `active_dataflow-connector-active_record`
- Version: Read from `ActiveDataFlow::ActiveRecord::VERSION`
- Authors/Email: ActiveDataFlow Team
- License: MIT
- Ruby Version: >= 2.7.0

**Files Inclusion**:
- Uses `Dir.glob("{lib}/**/*")` for all lib files
- Explicitly includes: README.md, LICENSE.txt, CHANGELOG.md
- Excludes: spec files, development artifacts

**Dependencies**:
- Runtime: active_data_flow-core-core (~> 0.1), activerecord (>= 6.0), activesupport (>= 6.0)
- Development: rspec (~> 3.12), sqlite3 (~> 1.4), rubocop (~> 1.50)

### 5. Documentation Files

**LICENSE.txt**:
- MIT License format
- Copyright: 2024 ActiveDataFlow Team
- Standard MIT license text

**CHANGELOG.md**:
- Follows Keep a Changelog format
- Adheres to Semantic Versioning
- Initial entry for version 0.1.0 documenting the connector's first release

## Data Models

No new data models are introduced in this setup phase. The existing models remain:

- `ActiveDataFlow::ActiveRecord::VERSION` - Version constant
- `ActiveDataFlow::Source::ActiveRecord` - Source connector class
- `ActiveDataFlow::Sink::ActiveRecord` - Sink connector class

## Error Handling

### Gemfile Errors
- **Missing Core Dependency**: If core_core symlink is broken, Bundler will fail with clear path error
- **Version Conflicts**: Bundler will report incompatible version constraints

### Init File Errors
- **Missing Dependencies**: LoadError will be raised if required gems are not installed
- **Load Order Issues**: Prevented by explicit require order in init file

### Gemspec Errors
- **Invalid Version**: Will fail at gem build time if version file is missing or malformed
- **Missing Files**: Gem build will warn about missing files referenced in spec

## Testing Strategy

### Validation Tests

1. **Gemfile Validation**:
   - Verify bundle install succeeds
   - Confirm core-core dependency resolves correctly
   - Check development dependencies are available in test environment

2. **Init File Validation**:
   - Verify `require 'active_data_flow-active_record'` loads without errors
   - Confirm all connector classes are accessible after require
   - Test load order by checking constant definitions

3. **Gemspec Validation**:
   - Run `gem build` to verify gemspec is valid
   - Confirm all specified files are included in built gem
   - Verify metadata is correctly set

4. **Documentation Validation**:
   - Verify LICENSE.txt exists and contains MIT license
   - Confirm CHANGELOG.md follows Keep a Changelog format
   - Check README.md is preserved

### Testing Approach

- Use RSpec for validation tests
- Create a spec file: `spec/project_setup_spec.rb`
- Tests should be non-destructive and verify file existence and content
- No mocking required - direct file system checks

## Implementation Notes

### Existing Files

The following files already exist and should be preserved:
- `lib/active_data_flow-active_record.rb` (may need updates)
- `lib/active_data_flow/active_record/version.rb`
- `lib/active_data_flow/source/active_record.rb`
- `lib/active_data_flow/sink/active_record.rb`
- `active_dataflow-connector-active_record.gemspec` (may need updates)
- `README.md`

### Files to Create

- `Gemfile` (new)
- `.kiro/specs/` directory structure (new)
- `LICENSE.txt` (new)
- `CHANGELOG.md` (new)

### Files to Update

- `lib/active_data_flow-active_record.rb` - Ensure proper require order and frozen_string_literal
- `active_dataflow-connector-active_record.gemspec` - Ensure it matches core-core pattern exactly

## Design Decisions

### Path-Based Dependency for Core

**Decision**: Use `path: 'core_core'` in Gemfile for active_data_flow-core-core dependency

**Rationale**: 
- Maintains consistency with existing symlink structure
- Enables local development without publishing gems
- Follows the pattern established in the repository structure

### Minimal .kiro Structure

**Decision**: Create only .kiro/specs directory initially

**Rationale**:
- Follows core-core pattern which only has specs subdirectory
- Keeps structure simple and extensible
- Additional .kiro subdirectories can be added as needed

### Frozen String Literal Pragma

**Decision**: Include `# frozen_string_literal: true` in all Ruby files

**Rationale**:
- Performance optimization (strings are immutable)
- Follows Ruby best practices
- Consistent with core-core implementation
- Will be default in future Ruby versions

### CHANGELOG Format

**Decision**: Use Keep a Changelog format with Semantic Versioning

**Rationale**:
- Industry standard for changelog documentation
- Human-readable and machine-parseable
- Consistent with core-core gem
- Supports automated tooling
