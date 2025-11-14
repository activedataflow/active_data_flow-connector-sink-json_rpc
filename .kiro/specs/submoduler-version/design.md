# Design Document: Submoduler Version Management

## Overview

The version management feature adds the ability to detect, report, and synchronize gem versions across all submodules in the monorepo. It follows the existing submoduler architecture pattern with a command class, supporting classes for version detection and manipulation, and a formatter for output.

## Architecture

### Command Pattern
Following the existing pattern in submoduler, we'll create a `VersionCommand` class that:
- Parses submodule entries using `GitModulesParser`
- Delegates version detection to `GemVersionDetector`
- Delegates version updates to `GemVersionUpdater`
- Uses `VersionFormatter` for output display

### Component Diagram

```
CLI
 └─> VersionCommand
      ├─> GitModulesParser (existing)
      ├─> GemVersionDetector (new)
      ├─> GemVersionUpdater (new)
      └─> VersionFormatter (new)
```

## Components and Interfaces

### 1. VersionCommand
**Responsibility:** Orchestrates version detection, comparison, and synchronization

**Interface:**
```ruby
class VersionCommand
  def initialize(repo_root, options = {})
  def execute
  private
  def detect_versions(entries)
  def check_version_mismatch(version_info)
  def synchronize_versions(version_info, target_version)
end
```

**Key Methods:**
- `execute`: Main entry point, coordinates the workflow
- `detect_versions`: Collects version information from all submodules
- `check_version_mismatch`: Determines if versions are inconsistent
- `synchronize_versions`: Updates versions when --sync flag is provided

### 2. GemVersionDetector
**Responsibility:** Extracts version information from gemspec and version files

**Interface:**
```ruby
class GemVersionDetector
  def initialize(submodule_path, submodule_name)
  def detect
  private
  def find_gemspec
  def extract_version_from_gemspec
  def find_version_file
  def extract_version_from_file
end
```

**Returns:** Hash with structure:
```ruby
{
  gem_name: "active_dataflow-core-core",
  version: "0.1.0",
  gemspec_path: "path/to/file.gemspec",
  version_file_path: "path/to/version.rb",
  error: nil  # or error message if detection failed
}
```

### 3. GemVersionUpdater
**Responsibility:** Updates version in gemspec and version.rb files

**Interface:**
```ruby
class GemVersionUpdater
  def initialize(version_info, new_version)
  def update
  private
  def update_version_file
  def update_gemspec_file
  def parse_version(version_string)
  def increment_version(version, increment_type)
end
```

**Version Increment Logic:**
- Parse current version (e.g., "0.1.0")
- Find highest version across all submodules
- Add 0.0.1 to highest version
- Update all submodules to new version

### 4. VersionFormatter
**Responsibility:** Formats version information for console output

**Interface:**
```ruby
class VersionFormatter
  def initialize(version_info, options = {})
  def format
  private
  def format_header
  def format_version_table
  def format_mismatch_warning
  def format_sync_summary
end
```

**Output Formats:**
- Table view: submodule name | gem name | version
- Mismatch warning with highest version highlighted
- Sync summary showing what was updated

## Data Models

### VersionInfo Structure
```ruby
{
  submodule_name: "core/core",
  gem_name: "active_dataflow-core-core",
  version: "0.1.0",
  gemspec_path: "submodules/core/core/active_dataflow-core-core.gemspec",
  version_file_path: "submodules/core/core/lib/active_dataflow/version.rb",
  error: nil
}
```

### Version Comparison Result
```ruby
{
  has_mismatch: true,
  highest_version: "0.1.2",
  versions: {
    "0.1.0" => ["core/core"],
    "0.1.2" => ["runtime/heartbeat_app"],
    "0.1.1" => ["connector/active_record"]
  }
}
```

## Error Handling

### Gemspec Not Found
- Return version_info with error: "No gemspec found"
- Display in table as "N/A"
- Don't count as mismatch

### Version File Not Found
- Try to extract from gemspec directly
- If both fail, return error
- Don't attempt to sync this submodule

### Invalid Version Format
- Display warning about non-standard version
- Attempt to parse as best as possible
- Skip synchronization if unparseable

### File Write Errors
- Catch and report file permission errors
- Rollback changes if partial update fails
- Exit with code 2 for system errors

## Testing Strategy

### Unit Tests
1. **GemVersionDetector**
   - Test gemspec parsing with various formats
   - Test version.rb file parsing
   - Test error handling for missing files
   - Test version extraction from different module structures

2. **GemVersionUpdater**
   - Test version increment logic
   - Test file update operations
   - Test rollback on partial failure
   - Test version format preservation

3. **VersionFormatter**
   - Test table formatting
   - Test mismatch highlighting
   - Test color output
   - Test dry-run output

### Integration Tests
1. Test full version detection across multiple submodules
2. Test version synchronization workflow
3. Test --dry-run mode
4. Test --submodule filtering
5. Test exit codes for various scenarios

## Implementation Notes

### Gemspec Parsing
Ruby gemspec files can have versions defined in multiple ways:
```ruby
# Direct string
spec.version = "0.1.0"

# From constant
spec.version = ActiveDataFlow::VERSION

# From file
require_relative "lib/active_data_flow/version"
spec.version = ActiveDataFlow::VERSION
```

We'll use a simple regex approach first, then fall back to requiring the version file if needed.

### Version File Patterns
Common patterns in Ruby gems:
```ruby
module ActiveDataFlow
  VERSION = "0.1.0"
end

# Or nested
module ActiveDataFlow
  module Core
    VERSION = "0.1.0"
  end
end
```

### Semantic Versioning
We'll support semantic versioning (MAJOR.MINOR.PATCH):
- Parse as three integers
- Increment patch version by 1
- Preserve format (e.g., quoted strings)

### Dry Run Implementation
- Detect all versions normally
- Calculate what would change
- Display changes without writing files
- Always exit with code 0

## CLI Integration

### New Command
Add to CLI.rb:
```ruby
when 'version'
  VersionCommand.new(@repo_root, options).execute
```

### New Options
- `--sync`: Enable version synchronization
- `--dry-run`: Preview changes without applying
- `--submodule <name>`: Filter to specific submodules

### Help Text Addition
```
version                 Manage gem versions across submodules

Version Options:
  --sync                  Synchronize versions across submodules
  --dry-run               Preview changes without applying
  --submodule <name>      Check specific submodule(s)
```

## Dependencies

### Existing Components
- `GitModulesParser`: Parse .gitmodules file
- `SubmoduleEntry`: Submodule data structure
- CLI option parsing infrastructure

### New Files
- `lib/submoduler/version_command.rb`
- `lib/submoduler/gem_version_detector.rb`
- `lib/submoduler/gem_version_updater.rb`
- `lib/submoduler/version_formatter.rb`

### External Dependencies
None - uses only Ruby standard library
